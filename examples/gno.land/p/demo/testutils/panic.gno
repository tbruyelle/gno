package testutils

import "testing"

func RequirePanic(t *testing.T, f func(), expRecover string) {
	defer func() {
		r := recover()
		if r == nil || r.(string) != expRecover {
			t.Fatalf("expected panic with %q, got %q", expRecover, r)
		}
	}()
	f()
}
