package httpapi

import (
	"errors"
	"net"
	"testing"
	"time"
)

func TestConnectionBudgetReleasesAndShutdownUnblocks(t *testing.T) {
	base, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	listener := &boundedListener{Listener: base, slots: make(chan struct{}, 1), done: make(chan struct{})}
	defer listener.Close()
	client, err := net.Dial("tcp", base.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()
	first, err := listener.Accept()
	if err != nil {
		t.Fatal(err)
	}
	accepted := make(chan net.Conn, 1)
	failures := make(chan error, 1)
	go func() {
		conn, err := listener.Accept()
		if err != nil {
			failures <- err
		} else {
			accepted <- conn
		}
	}()
	secondClient, err := net.Dial("tcp", base.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	defer secondClient.Close()
	select {
	case conn := <-accepted:
		conn.Close()
		t.Fatal("connection budget exceeded")
	case <-time.After(25 * time.Millisecond):
	}
	first.Close()
	var second net.Conn
	select {
	case second = <-accepted:
	case err := <-failures:
		t.Fatal(err)
	case <-time.After(time.Second):
		t.Fatal("slot not released")
	}
	go func() { _, err := listener.Accept(); failures <- err }()
	listener.Close()
	select {
	case err := <-failures:
		if !errors.Is(err, net.ErrClosed) {
			t.Fatal("shutdown did not report closed listener")
		}
	case <-time.After(time.Second):
		t.Fatal("shutdown left Accept blocked")
	}
	second.Close()
	second.Close()
}
