open WebAPI

let props = Set.fromArray([
  "accept",
  "acceptCharset",
  "accessKey",
  "action",
  "align",
  "alt",
  "autoplay",
  "checked",
  "cite",
  "contentEditable",
  "controls",
  "coords",
  "default",
  "dir",
  "download",
  "dropzone",
  "enctype",
  "headers",
  "hidden",
  "href",
  "hreflang",
  "htmlFor",
  "id",
  "kind",
  "label",
  "lang",
  "loop",
  "max",
  "method",
  "min",
  "name",
  "pattern",
  "ping",
  "placeholder",
  "poster",
  "preload",
  "scope",
  "selected",
  "shape",
  "span",
  "spellcheck",
  "src",
  "srcdoc",
  "srclang",
  "sandbox",
  "start",
  "step",
  "target",
  "title",
  "type",
  "useMap",
  "value",
  "wrap",
])

@set_index external setPropertyIndexed: (DOMAPI.element, string, unknown) => unit = ""

let setProperty = (prop, value, el) => {
  if Set.has(props, prop) {
    el->setPropertyIndexed(prop, value)
  } else {
    let value: string = Obj.magic(value)
    el->Element.setAttribute(~qualifiedName=prop, ~value)
  }
}
