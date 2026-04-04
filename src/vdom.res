open WebAPI
type rec node =
  | ElementNode({tag: string, attributes: dict<string>, children: array<node>})
  | TextNode(string)

type diffOperation =
  | Create(node)
  | Remove
  | Replace(node)
  | Modify({remove: array<string>, set: dict<string>, children: array<node>})
  | Nothing

let h = (tag, ~attributes=dict{}, children) => {
  ElementNode({
    tag,
    attributes,
    children,
  })
}

let text = (str: string): node => {TextNode(str)}

let rec diffOne = (l, r) => {
  switch (l, r) {
  // if text nodes match do nothing
  | (TextNode(tl), TextNode(tr)) if tl == tr => Nothing

  // if text nodes do not match replace
  | (TextNode(tl), TextNode(tr)) if tl != tr => Replace(r)

  // if the tags are not the same just replace
  | (ElementNode(el), ElementNode(er)) if el.tag != er.tag => Replace(r)

  // nodes have the same tag, so figure out what attributes and children need to be replaced
  | (ElementNode(l), ElementNode(r)) => {
      // get attributes to remove
      let remove = []
      Dict.forEachWithKey(l.attributes, (v, k) => {
        switch Dict.get(r.attributes, k) {
        | None => Array.push(remove, v)
        | Some(_) => ()
        }
      })

      // get attributes to set
      let set = dict{}
      Dict.forEachWithKey(r.attributes, (rv, k) => {
        switch Dict.get(l.attributes, k) {
        | Some(lv) if lv == rv => ()
        | _ => Dict.set(set, k, rv)
        }
      })

      let children = []
      Modify({remove, set, children})
    }
  | (_, _) => Replace(r) // different node types, so replace the node
  }
}
and diffList = (ls, rs) => {
  let length = Math.Int.max(Array.length(ls), Array.length(rs))
  let changeList = []
  for i in 0 to length - 1 {
    switch (ls[i], rs[i]) {
    | (Some(lv), Some(rv)) => Array.push(changeList, diffOne(lv, rv))
    | (Some(_), None) => Array.push(changeList, Remove)
    | (None, Some(rv)) => Array.push(changeList, Create(rv))
    | _ => () // should never get here
    }
  }
}

let testStuff = () => {
  h(
    "div",
    [
      h("h2", [text("Game Paused")]),
      h("button", [text("Game Paused")]),
      h("button", [text("Game Paused")]),
    ],
  )
}

external htmlCollectionToArray: DOMAPI.htmlCollection => array<DOMAPI.element> = "Array.from"

let apply = (el: DOMAPI.element, childrenDiff) => {
  let children = htmlCollectionToArray(el.children)
  childrenDiff->Array.forEachWithIndex((diff, i) => {
    switch diff {
    | Remove =>
      switch children[i] {
      | Some(child) => Element.remove(child)
      | None => ()
      }
    | Modify(modify) => // modify(children[i])
      ()
    | Create(node) => // let child = create(node)
      // Element.appendChild(child)
      ()
    | Replace(node) => // let child = create(node)
      // children[i]
      // Element.replaceWith(child)
      ()
    | _ => ()
    }
  })
}
