# elm-action
This module lets you organize your update function for different states.

For example:

        update : Msg -> Model -> (Model, Cmd Msg)
        update msg model =
            case (msg,model) of
                (LoggedIn guestMsg,Nothing) ->
                    updateGuest guestMsg
                    |> Action.config
                    |> Action.withTransition
                        (\name ->
                          (Just <| initUser name,Cmd.none)
                        )
                    |> Action.withUpdate (always Nothing) never
                    |> Action.apply
                (UserSpecific userMsg,Just user) ->
                    updateUser userMsg
                    |> Action.config
                    |> Action.withUpdate Just UserSpecific
                    |> Action.withExit (Nothing,Cmd.none)

Here we have two states: `Guest` and `User`. Each of them has there own update
function:

        updateGuest : {name:String,pass:String} -> GuestAction
        updateGuest {name,pass} =
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

Under the hood, an `Action` is a state transition of a
[state machine](https://en.wikipedia.org/wiki/Finite-state_machine).
The corresponding state machine looks like this:

       LoggedOut?  +--User<-+   !pass == "password"
                   |        |
                   v        |
                   +->Guest-+   ?LoggedIn => pass == "password"?
                       ^    |
                       +----+   !pass /= "password"