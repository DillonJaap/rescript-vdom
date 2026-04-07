open WebAPI

type uiObject = {listeners: Dict.t<EventAPI.event => unit>}

@get external getUI: DOMAPI.element => uiObject = "_ui"
@set external setUI: (DOMAPI.element, Dict.t<'a>) => unit = "_ui"

external eventTypeToString: EventAPI.eventType => string = "%identity"

let listener = (event: EventAPI.event) => {
  switch Null.toOption(event.currentTarget) {
  | None => ()
  | Some(target) =>
    let ui = getUI(target->Obj.magic)
    switch Dict.get(ui.listeners, eventTypeToString(event.type_)) {
    | Some(handler) => handler(event)
    | None => ()
    }
  }
}

let setListener = (el: DOMAPI.element, eventType: EventAPI.eventType, handle) => {
  let ui = getUI(el)
  if !Dict.has(ui.listeners, (eventType :> string)) {
    Element.addEventListener(el, eventType, listener)
  }
  Dict.set(ui.listeners, (eventType :> string), handle)
}

let setEmptyListeners = (el: DOMAPI.element) => {
  let listeners = Dict.make()
  let ui: uiObject = {listeners: listeners}
  setUI(el, ui->Obj.magic)
}

let eventName = (str: string) => {
  if String.startsWith(str, "on") {
    let eventString = str->String.slice(~start=2)->String.toLowerCase
    let eventType = (eventString :> EventAPI.eventType)
    Some(eventType)
  } else {
    None
  }
}
