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

func CreateList(name, description string) ListID {
	l := newList(name, description)
	listsByName.Set(name, l)
	listsByID.Set(l.id.String(), l)
	return l.id
}

func GetList(id ListID) *List {
	n, exists := listsByID.Get(id.String())
	if !exists {
		return nil
	}
	return n.(*List)
}

func SubscribeList(id ListID) {
	std.AssertOriginCall()
	list := GetList(id)
	if list == nil {
		panic("list not found")
	}
	caller := std.GetOrigCaller()
	list.q.Push(caller)
}

func Render(path string) string {
	var str string
	listsByID.Iterate("", "", func(n *avl.Node) bool {
		list := n.Value().(*List)
		str += list.id.String() + " " +
			list.name + " " +
			list.creator.String() + " " +
			strconv.Itoa(list.q.Length()) + "\n"
		return false
	})
	return str
}
