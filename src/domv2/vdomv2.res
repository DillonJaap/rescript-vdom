open WebAPI

// VDOM types
type attribute =
  | String(string)
  | EventHandler(EventAPI.event => unit)

// TODO tag is a varient?
type tag = string

type rec vnode =
  | Node({tag: tag, attributes: dict<attribute>, children: array<vnode>})
  | Text(string)

let h = (tag: tag, ~attributes=[]: array<(string, attribute)>, children: array<vnode>) => {
  Node({tag, attributes: attributes->Dict.fromArray, children})
}

let text = (str: string): vnode => {
  Text(str)
}

// diffing

type diffOperation =
  | Create(vnode)
  | Replace(vnode)
  | Modify({remove: array<string>, set: array<(string, attribute)>})
  | Remove
  | Nothing

let diffOne = (old: vnode, new: vnode): diffOperation => {
  switch (old, new) {
  // If text nodes match do nothing
  | (Text(text_old), Text(text_new)) if text_old == text_new => Nothing

  // If text nodes do not match replace
  | (Text(text_old), Text(text_new)) if text_old != text_new => Replace(new)

  // If tags are not the same just replace them
  | (Node(node_old), Node(node_new)) if node_old.tag != node_new.tag => Replace(new)

  // Nodes have the same tag, we need to modify the attributes
  | (Node(node_old), Node(node_new)) => {
      let remove_attrs = []
      Dict.forEachWithKey(node_old.attributes, (_attr, key) => {
        if node_new.attributes->Dict.has(key) {
          remove_attrs->Array.push(key)
        }
      })

      let set_attrs = []
      Dict.forEachWithKey(node_new.attributes, (attr, key) => {
        if node_old.attributes->Dict.getUnsafe(key) == attr {
          set_attrs->Array.push((key, attr))
        }
      })

      Modify({remove: remove_attrs, set: set_attrs})
    }

  // Node types are different so replace
  | (_, _) => Replace(new)
  }
}
