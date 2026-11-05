// SPDX-License-Identifier: GPL-3.0-or-later
package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: dns-probe https://server.example.com/api/v1/version")
		os.Exit(2)
	}
	u, err := url.Parse(os.Args[1])
	if err != nil || u.Scheme != "https" || u.Host == "" || u.User != nil {
		fmt.Fprintln(os.Stderr, "an HTTPS URL without credentials is required")
		os.Exit(2)
	}
	client := &http.Client{Timeout: 15 * time.Second}
	response, err := client.Get(u.String())
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		fmt.Fprintln(os.Stderr, response.Status)
		os.Exit(1)
	}
	if _, err := io.Copy(os.Stdout, response.Body); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
