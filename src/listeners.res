open WebAPI

type uiObject = {
  listeners: Dict.t<EventAPI.event => unit>,
}

@get external getUI: EventAPI.eventTarget => uiObject = "_ui"
external eventTypeToString: EventAPI.eventType => string = "%identity"

let getListeners = (event: EventAPI.event) => {
  let? Some(target) = Null.toOption(event.currentTarget)
  Some(getUI(target).listeners)
}

let listener = (event: EventAPI.event) => {
  let _ = {
    let? Some(listeners) = getListeners(event)
    let? Some(handler) = listeners->Dict.get(eventTypeToString(event.type_))
    handler(event)
    None
  }
}

let setListener = (el, event, handle) => {
  let listener_event = {
    let? Some(listeners) = getListeners(event)
    listeners->Dict.get(eventTypeToString(event.type_))
  }

  switch listener_event {
  | Some(_) => ()
  | None => Element.addEventListener(el, event.type_, listener)
  }

  let _ = {
    let? Some(listeners) = getListeners(event)
    listeners->Dict.set(eventTypeToString(event.type_), handle)
    None
  }
}

let eventName = str => {
  switch String.indexOf(str, "on") == 0 {
  | true => Some(String.slice(str, 0, 2)->String.toLowerCase())
  | false => None
  }
}
