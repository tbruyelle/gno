package queue

import (
	"testing"
)

func TestQueue(t *testing.T) {
	q := New()
	if q.Pop() != nil {
		t.Fatal("Pop doesn't return nil")
	}
	assertLength := func(length int) {
		if q.Length() != length {
			t.Fatalf("expected length %d, got %d", length, q.Length())
		}
	}
	assertLength(0)
	q.Push(7)
	assertLength(1)
	q.Push(2)
	assertLength(2)
	q.Push(4)
	assertLength(3)
	var res []int
	for {
		i := q.Pop()
		if i == nil {
			break
		}
		res = append(res, i.(int))
		assertLength(3 - len(res))
	}
	expected := []int{7, 2, 4}
	if len(res) != len(expected) {
		t.Fatalf("expected %v got %v", expected, res)
	}
	for i := 0; i < len(res); i++ {
		if res[i] != expected[i] {
			t.Fatalf("expected %v got %v", expected, res)
		}
	}
}
