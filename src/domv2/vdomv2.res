open WebAPI

// VDOM types
type attribute =
  | Attribute(string, string)
  | EventHandlerAttribute(string, EventAPI.event => unit)

type tag = string

type rec vnode =
  // TODO tag is a varient
  | Node({tag: tag, attributes: list<attribute>, children: list<vnode>})
  | Text(string)

let h = (tag: tag, ~attributes=list{}: list<attribute>, children: list<vnode>) => {
  Node({tag, attributes, children})
}

let text = (str: string): vnode => {
  Text(str)
}

// diffing

type diffOperation =
  | Create(vnode)
  | Replace(vnode)
  | Modify({remove: list<string>, set: list<attribute>})
  | Remove
  | Nothing

let rec diffOne = (old: vnode, new: vnode): diffOperation => {
  switch (old, new) {
  // If text nodes match do nothing
  | (Text(text_old), Text(text_new)) if text_old == text_new => Nothing

  // If text nodes do not match replace
  | (Text(text_old), Text(text_new)) if text_old != text_new => Replace(new)

  // If tags are not the same just replace them
  | (Node(node_old), Node(node_new)) if node_old.tag != node_new.tag => Replace(new)

  // Nodes have the same tag, we need to modify the attributes
  | (Node(node_old), Node(node_new)) => {
      let remove_attrs = list{}
      let set_attrs = list{}

      Modify({remove: remove_attrs, set: set_attrs})
    }
  | _ => Nothing
  }
}
