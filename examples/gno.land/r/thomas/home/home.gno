package home

import "gno.land/p/moul/md"

func Render() string {
	content := md.H1("Thomas' Home")
	content += md.Paragraph("Hello there, I'm Thomas and I'm a blockchain engineer at All-In-Bits.")
	content += md.H3("Project's list")
	content += md.BulletList([]string{"Emeris", "Starport/Ignite", "Gno.land", "Decentralists", "AtomOne"})
	return content
}
