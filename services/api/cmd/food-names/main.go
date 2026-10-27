package main

import (
	"fmt"
	"os"
	"trainforge.local/api/internal/foodnamesops"
)

func main() {
	if err := foodnamesops.Run(os.Args[1:], os.Getenv, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
