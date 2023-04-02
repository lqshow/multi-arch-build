package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"

	"github.com/lqshow/multi-arch-build/pkg/version"
	"github.com/spf13/pflag"
)

func homePage(w http.ResponseWriter, r *http.Request) {
	host, err := os.Hostname()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "Welcome to the HomePage! \n\nHostname is %s, ARCH is %s", host, runtime.GOARCH)

	fmt.Println("Endpoint Hit: homePage")
}

func main() {
	showVersion := pflag.Bool("version", false, "Print the version and exit")
	pflag.Parse()

	if *showVersion {
		versionMeta, err := version.GetVersionJSON()
		if err != nil {
			log.Fatalf("Error getting version: %s", err)
		}
		fmt.Println("Version:", versionMeta)
		return
	}

	http.HandleFunc("/", homePage)
	log.Fatal(http.ListenAndServe(":3000", nil))
}
