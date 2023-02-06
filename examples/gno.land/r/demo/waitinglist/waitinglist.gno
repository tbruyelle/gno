package waitinglist

import (
	"std"
	"strconv"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/queue"
)

var (
	listsByID   avl.Tree
	listsByName avl.Tree
	listCtr     int
)

type ListID int

func (id ListID) String() string {
	return strconv.Itoa(int(id))
}

type List struct {
	id          ListID
	creator     std.Address
	name        string
	description string
	q           *queue.Queue
	subs        avl.Tree
}

func CreateList(name, description string) ListID {
	l := newList(name, description)
	listsByName.Set(name, l)
	listsByID.Set(l.id.String(), l)
	return l.id
}

func newList(name, description string) *List {
	std.AssertOriginCall()
	caller := std.GetOrigCaller()
	if listsByName.Has(name) {
		panic("list name already exists")
	}
	listCtr++
	l := &List{
		id:          ListID(listCtr),
		creator:     caller,
		name:        name,
		description: description,
		q:           queue.New(),
	}
	return l
}

func GetList(id ListID) *List {
	n, exists := listsByID.Get(id.String())
	if !exists {
		return nil
	}
	return n.(*List)
}

func mustGetList(id ListID) *List {
	list := GetList(id)
	if list == nil {
		panic("list not found")
	}
	return list
}

func SubscribeList(id ListID) {
	std.AssertOriginCall()
	list := mustGetList(id)
	caller := std.GetOrigCaller()
	if _, found := list.subs.Get(caller.String()); found {
		panic("already subscribed")
	}
	list.q.Push(caller)
	list.subs.Set(caller.String(), caller)
}

func ListNext(id ListID) string {
	std.AssertOriginCall()
	list := mustGetList(id)
	caller := std.GetOrigCaller()
	if list.creator != caller {
		panic("only list creator can call ListNext")
	}
	next := list.q.Pop()
	if next == nil {
		panic("empty list")
	}
	addr := next.(std.Address).String()
	list.subs.Remove(addr)
	return addr
}

func (l List) render() string {
	return l.id.String() + " " +
		l.name + " " +
		l.creator.String() + " " +
		strconv.Itoa(l.q.Length()) + "\n"
}

func Render(path string) string {
	if path == "" {
		var str string
		listsByID.Iterate("", "", func(n *avl.Node) bool {
			list := n.Value().(*List)
			str += list.render()
			return false
		})
		return str
	}
	// path contains the id of a waiting list
	id, err := strconv.Atoi(path)
	if err != nil {
		panic(err)
	}
	return mustGetList(ListID(id)).render()
}
