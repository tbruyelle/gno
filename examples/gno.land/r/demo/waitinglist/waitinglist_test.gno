package waitinglist

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"
	"gno.land/p/demo/ufmt"
)

func TestCreateList(t *testing.T) {
	user := testutils.TestAddress("user")
	std.TestSetOrigCaller(user)

	id := CreateList("list1", "desc1")

	if id != 1 {
		t.Fatalf("invalid id expected 1 got %d", id)
	}
	expectedRender := ufmt.Sprintf("1 list1 %s 0\n", user.String())
	if render := Render(""); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}

	id = CreateList("list2", "desc2")

	if id != 2 {
		t.Fatalf("invalid id expected 2 got %d", id)
	}
	expectedRender = ufmt.Sprintf("1 list1 %s 0\n2 list2 %s 0\n", user.String(), user.String())
	if render := Render(""); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}
}

func TestSubscribeList(t *testing.T) {
	user := testutils.TestAddress("user")
	std.TestSetOrigCaller(user)
	id := CreateList(t.Name(), "")

	SubscribeList(id)

	expectedRender := ufmt.Sprintf("%s %s %s 1\n", id.String(), t.Name(), user.String())
	if render := Render(id.String()); render != expectedRender {
		t.Fatalf("invalid Render, expected\n%s\ngot\n%s", expectedRender, render)
	}

	testutils.RequirePanic(t, func() {
		SubscribeList(id)
	}, "already subscribed")
}

func TestListNext(t *testing.T) {
	user := testutils.TestAddress("user")
	std.TestSetOrigCaller(user)
	id := CreateList(t.Name(), "")
	sub1 := testutils.TestAddress("sub1")
	std.TestSetOrigCaller(sub1)
	SubscribeList(id)
	sub2 := testutils.TestAddress("sub2")
	std.TestSetOrigCaller(sub2)
	SubscribeList(id)

	testutils.RequirePanic(t, func() {
		ListNext(id)
	}, "only list creator can call ListNext")

	std.TestSetOrigCaller(user)

	next := ListNext(id)

	if next != sub1 {
		t.Fatalf("expected next %s got %s", sub1, next)
	}

	next = ListNext(id)

	if next != sub2 {
		t.Fatalf("expected next %s got %s", sub2, next)
	}

	testutils.RequirePanic(t, func() {
		ListNext(id)
	}, "empty list")

	// sub2 subscribes again
	SubscribeList(id)
}
