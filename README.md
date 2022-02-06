# elm-action

## DEPRECATED

Use [Elm-Spa](https://www.elm-spa.dev/) instead

---

This module lets you organize your update function for different states.

For example:

```elm
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( GuestSpecific guestMsg, Guest ) ->
            updateGuest guestMsg
                |> Action.config
                |> Action.withTransition initUser User never
                |> Action.withUpdate (always Guest) never
                |> Action.apply

        ( UserSpecific userMsg, User userModel ) ->
            updateUser userMsg
                |> Action.config
                |> Action.withUpdate User UserSpecific
                |> Action.withExit ( Guest, Cmd.none )
                |> Action.apply
```

Here we have two states: `Guest` and `User`. Each of them has there own update
function:

```elm
updateGuest : GuestMsg -> GuestAction
updateGuest msg =
    case msg of
        LoggedIn {name,pass} ->
            if pass = "password" then
                Action.transitioning name
            else
                Action.updating ((),Cmd.none)

updateUser : UserMsg -> User -> UserAction
updateUser msg user =
    case msg of
        Commented string ->
            Debug.todo "send comment to server"
        LoggedOut ->
            Action.exiting
```

Under the hood, an `Action` is a state transition of a
[state machine](https://en.wikipedia.org/wiki/Finite-state_machine).
The corresponding state machine looks like this:

       LoggedOut?  +--User<-+   !pass == "password"
                   |        |
                   v        |
                   +->Guest-+   ?LoggedIn => pass == "password"?
                       ^    |
                       +----+   !pass /= "password"

# Alternative Solutions

I've seen multiple different approaches for the same problem and it might be that my solution isn't suitable for your needs.

- In the [Elm Spa Example](https://github.com/rtfeldman/elm-spa-example/blob/master/src/Main.elm), a helper function `updateWith` is used for the wiring. Transitions are all defined in the function `changeRouteTo`. Personally I like to model my app as a state machine. But if you don't, then the approach in the SPA example will be better for you.
- [the-sett/elm-state-machines](https://package.elm-lang.org/packages/the-sett/elm-state-machines/latest/) has the same idea as I do, but implements it using phantom types. Instead of phantom types, I use the config pipeline to specify what actions are allowed.
- [turboMaCk/glue](https://package.elm-lang.org/packages/turboMaCk/glue/latest/) introduces the concept of subModules. This makes a lot of sense for reusable views. If you only use reusable views, then use that package instead.
