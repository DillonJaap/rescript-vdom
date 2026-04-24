/*****************************************************************************/
/* VDOM types */
/*****************************************************************************/

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

/*****************************************************************************/
/* diffing */
/*****************************************************************************/
type rec diffOperation =
  | Create(vnode)
  | Replace(vnode)
  | Modify({remove: array<string>, set: array<(string, attribute)>, children: array<diffOperation>})
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

      let children = diffList(node_old.children, node_new.children)
      Modify({remove: remove_attrs, set: set_attrs, children})
    }

  // Node types are different so replace
  | (_, _) => Replace(new)
  }
}

and diffList = (old: array<vnode>, new: array<vnode>) => {
  let length = Math.Int.max(old->Array.length, new->Array.length)
  Array.fromInitializer(~length, i => {
    switch (old[i], new[i]) {
    | (Some(old_node), Some(new_node)) => diffOne(old_node, new_node)
    | (None, Some(new_node)) => Create(new_node)
    | (Some(_old_node), None) => Remove

    // should never reach here
    | _ => Nothing
    }
  })
}

/*****************************************************************************/
/* DOM helpers */
/*****************************************************************************/
let removeNode = (node: DOMAPI.node) => {
  switch Null.toOption(node.parentNode) {
  | Some(parent) => Node.removeChild(parent, node)->ignore
  | None => ()
  }
}

/*****************************************************************************/
/* application */
/*****************************************************************************/
let apply = (el: DOMAPI.element, childrenDiff: array<diffOperation>) => {
  let children = Array.fromInitializer(~length=el.childNodes.length, i => {
    el.childNodes->NodeListOf.item(i)
  })

  childrenDiff->Array.forEachWithIndex((diff, i) => {
			switch (diff, children[i]) {
			| (Remove, Some(child))  =>  child->removeNode
			|_  => ()
			}
			})
}
