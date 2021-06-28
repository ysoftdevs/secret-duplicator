package main

import (
	"context"
	"crypto/tls"
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/golang/glog"
)

func main() {
	parameters := DefaultParametersObject()

	// get command line parameters
	flag.IntVar(&parameters.port, "port", LookupIntEnv("CONFIG_PORT", parameters.port), "Webhook server port.")
	flag.StringVar(&parameters.certFile, "tlsCertFile", LookupStringEnv("CONFIG_CERT_PATH", parameters.certFile), "File containing the x509 Certificate for HTTPS.")
	flag.StringVar(&parameters.keyFile, "tlsKeyFile", LookupStringEnv("CONFIG_KEY_PATH", parameters.keyFile), "File containing the x509 private key to --tlsCertFile.")
	flag.StringVar(&parameters.excludeNamespaces, "excludeNamespaces", LookupStringEnv("CONFIG_EXCLUDE_NAMESPACES", parameters.excludeNamespaces), "Comma-separated namespace names to ignore.")

	flag.StringVar(&parameters.targetSecretAnnotation, "targetSecretAnnotation", LookupStringEnv("CONFIG_TARGET_SECRET_ANNOTATION", parameters.targetSecretAnnotation), "Annotation of the targetSecret secret we will create in the namespace")
	flag.StringVar(&parameters.targetSecretName, "targetSecretName", LookupStringEnv("CONFIG_TARGET_SECRET_NAME", parameters.targetSecretName), "Name of the targetSecret secret we will create in the namespace")

	flag.Parse()

	glog.Infof("Running with config: %+v", parameters)

	whsvr, err := NewWebhookServer(
		&parameters,
		&http.Server{
			Addr: fmt.Sprintf(":%v", parameters.port),
			// This is quite inefficient as it loads file contents on every TLS ClientHello, but ¯\_(ツ)_/¯
			TLSConfig: &tls.Config{GetCertificate: func(info *tls.ClientHelloInfo) (*tls.Certificate, error) {
				glog.Infof("Loading certificates")
				cert, err := tls.LoadX509KeyPair(parameters.certFile, parameters.keyFile)
				return &cert, err
			}},
		},
	)
	if err != nil {
		glog.Exitf("Could not create the Webhook server: %v", err)
	}

	// define http server and server handler
	mux := http.NewServeMux()
	mux.HandleFunc("/mutate", whsvr.serve)
	whsvr.server.Handler = mux

	// start webhook server in new rountine
	go func() {
		if err := whsvr.server.ListenAndServeTLS(parameters.certFile, parameters.keyFile); err != nil {
			glog.Errorf("Failed to listen and serve webhook server: %v", err)
		}
	}()

	// listening OS shutdown singal
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, syscall.SIGINT, syscall.SIGTERM)
	<-signalChan

	glog.Infof("Got OS shutdown signal, shutting down webhook server gracefully...")
	if err := whsvr.server.Shutdown(context.Background()); err != nil {
		glog.Errorf("Error while shutting down: %v", err)
	}
}
