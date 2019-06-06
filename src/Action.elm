module Action exposing
    ( Action, updating, transitioning, exiting
    , config, apply, withUpdate, withTransition, withExit
    )

{-| There is a quick guideline to follow if you want to use this module:

1.  Add a type alias. For example:

         type alias UserAction =
             Action
                 Never --Allow Updates?
                 Never --Allow Cmd other then Cmd.none?
                 Never --Allow Transitions?
                 Never --Allow Exit?

2.  Start by setting the first `Never` to your `stateModel`:

         type alias UserAction =
             Action
                 UserModel -- updates allowed.
                 Never --Allow Cmd other then Cmd.none?
                 Never --Allow Transitions?
                 Never --Allow Exit?

    If you want to allow Cmd, change the second Never to your `stateMsg`. In our
    example, this would be `UserMsg`.

3.  Write your update function. In our very basic example, it looks like this:

         update : Msg -> Model -> (Model, Cmd Msg)
         update msg model =
             case msg of
                 (UserSpecific userMsg,User userModel) ->
                     updateUser userMsg userModel
                     |> Action.config
                     |> Action.withUpdate User never
                     -- If you want to allow Cmd you would use
                     -- the following line
                     --|> Action.withUpdate User UserSpecific
                     |> Action.apply

                 _ ->
                     (model,Cmd.none)

4.  If needed, go back to Step 2 and replace another `Never`.


# Actions

@docs Action, updating, transitioning, exiting


# Config Pipeline

@docs config, apply, withUpdate, withTransition, withExit

-}


type alias Config exit modelMapper msgMapper transition =
    { exitFun : exit
    , modelMapper : modelMapper
    , msgMapper : msgMapper
    , transitionFun : transition
    }


type alias ActionConfig stateModel stateMsg transitionData exitAllowed configBuilder =
    ( Action stateModel stateMsg transitionData exitAllowed, configBuilder )


map :
    (configBuilder1
     -> configBuilder2
    )
    -> ActionConfig stateModel stateMsg transitionData exitAllowed configBuilder1
    -> ActionConfig stateModel stateMsg transitionData exitAllowed configBuilder2
map fun =
    Tuple.mapSecond fun


{-| An `Action` specifies the behaviour of an update function.
An `Action` can either be

  - `Update (model,Cmd msg)` - Updates the model as usual.
  - `Transition transitionData` - Transitions to a different model using `data` (like logging in)
  - `Exit` - Transitions to a different model with less access (like logging out)

An `Action` has 4 type parameters: `model`,`msg`,`transitionData` and `exitAllowed`.

  - The type of `exitAllowed` should be set to `()`. However,
  - If you want to forbid `Exit`, then set `exitAllowed` to `Never`.
  - If you want to forbid `Update (model,Cmd msg)`, then set `model` to `Never`.
  - If you want to forbid `Cmd msg` other then `Cmd.none`, then set `msg` to `Never`.
  - If you want to forbid `Transition transitionData`, then set `transitionData` to `Never`.

-}
type Action model msg transitionData exitAllowed
    = Update ( model, Cmd msg )
    | Transition transitionData
    | Exit exitAllowed


{-| Updates the model as usual.

    import Task

    updating (42, Cmd.none)
    |> Action.config
    |> Action.withUpdate (\int -> (int,0)) never
    |> Action.apply
    |> Tuple.first
    --> (42,0)

Checklist in case of errors:

  - `stateModel` should not be `Never`
  - the config pipeline should include `withUpdate`

-}
updating : ( stateModel, Cmd stateMsg ) -> Action stateModel stateMsg transitionData exitAllowed
updating tuple =
    Update tuple


{-| Transitions to a different model.

    import Task

    transitioning 42
    |> Action.config
    |> Action.withTransition (\int -> ((int,0),Cmd.none)) Just never
    |> Action.apply
    |> Tuple.first
    --> Just (42,0)

Checklist in case of errors:

  - `transitionData` should not be `Never`
  - the config pipeline should include `withTransition`

-}
transitioning : transitionData -> Action stateModel stateMsg transitionData exitAllowed
transitioning transitionData =
    Transition transitionData


{-| Transitions to a different model with less access. (like logging out)

    import Task

    exiting
    |> Action.config
    |> Action.withExit ((42,0),Cmd.none)
    |> Action.apply
    |> Tuple.first
    --> (42,0)

Checklist in case of errors:

  - `exitAllowed` should be `()`
  - the config pipeline should include `withExit`

-}
exiting : Action stateModel stateMsg transitionData ()
exiting =
    Exit ()


{-| Starts the configuration of the Action.

The most basic config pipeline looks like this:

    updateFunction
        |> Action.config
        |> Action.apply

with `updateFunction : Model -> Msg -> Action Model Msg TransitionData ExitAllowed`.

You will need to add `withExit`,`withUpdate` and or `withTransition` to make
the code compile.

-}
config :
    Action stateModel stateMsg transitionData exitAllowed
    -> ActionConfig stateModel stateMsg transitionData exitAllowed (Config (Never -> ( model, Cmd msg )) (Never -> model) (Never -> msg) (Never -> ( model, Cmd msg )))
config action =
    ( action
    , { exitFun = never
      , modelMapper = never
      , msgMapper = never
      , transitionFun = never
      }
    )


{-| Specifies the state the resulting `(model, Cmd msg)` when exiting.

For a hard exit you can use

    withExit (init ())

Checklist in case of errors:

  - `exitAllowed` should be `()`
  - the config pipeline should include `withExit`

-}
withExit :
    ( model, Cmd msg )
    -> ActionConfig stateModel stateMsg transitionData () (Config (Never -> ( model, Cmd msg )) b c d)
    -> ActionConfig stateModel stateMsg transitionData () (Config (() -> ( model, Cmd msg )) b c d)
withExit a =
    map
        (\{ exitFun, modelMapper, msgMapper, transitionFun } ->
            { exitFun = always a
            , modelMapper = modelMapper
            , msgMapper = msgMapper
            , transitionFun = transitionFun
            }
        )


{-| Specifies how the `stateModel`/`stateMsg` is embedded in the main `model`/`msg`.

Lets say we have a password protected area:

    type Model
        = Maybe RestrictedModel

    type Msg
        = GuestSpecific GuestMsg
        | RestrictedSpecific RestrictedMsg

Then we would use `withUpdate Just RestrictedSpecific` for the restricted area and
`withUpdate (always Nothing) GuestSpecific` for the guest area.

Checklist in case of errors:

  - `stateModel` should not be `Never`
  - the config pipeline should include `withUpdate`

-}
withUpdate :
    (stateModel -> model)
    -> (stateMsg -> msg)
    -> ActionConfig stateModel2 stateMsg transitionData exitAllowed (Config a b c d)
    -> ActionConfig stateModel2 stateMsg transitionData exitAllowed (Config a (stateModel -> model) (stateMsg -> msg) d)
withUpdate a b =
    map
        (\{ exitFun, modelMapper, msgMapper, transitionFun } ->
            { exitFun = exitFun
            , modelMapper = a
            , msgMapper = b
            , transitionFun = transitionFun
            }
        )


{-| Specifies how the state transitions to another state.

Lets say we want a user to login.

    type alias User =
        { name : String
        , admin : Bool
        }

    initUser : String -> User
    initUser string =
        { name = string
        , admin = string == "Admin"
        }

    type Model
        = Maybe User

Then we can use `withTransition \string -> (Just <| initUser string, Cmd.none)`
for logging in a user.

Checklist in case of errors:

  - `transitionData` should not be `Never`
  - the config pipeline should include `withTransition`

-}
withTransition :
    (transitionData -> ( stateModel2, Cmd stateMsg2 ))
    -> (stateModel2 -> model)
    -> (stateMsg2 -> msg)
    -> ActionConfig stateModel stateMsg transitionData2 exitAllowed (Config a b c d)
    -> ActionConfig stateModel stateMsg transitionData2 exitAllowed (Config a b c (transitionData -> ( model, Cmd msg )))
withTransition a mapState mapMsg =
    map
        (\{ exitFun, modelMapper, msgMapper, transitionFun } ->
            { exitFun = exitFun
            , modelMapper = modelMapper
            , msgMapper = msgMapper
            , transitionFun =
                a >> (\( s, c ) -> ( mapState s, c |> Cmd.map mapMsg ))
            }
        )


{-| Ends the Configuration and returns a `(Model, Cmd Msg)`.
-}
apply :
    ActionConfig stateModel
        stateMsg
        transitionData
        exitAllowed
        { exitFun : exitAllowed -> ( model, Cmd msg )
        , modelMapper : stateModel -> model
        , msgMapper : stateMsg -> msg
        , transitionFun : transitionData -> ( model, Cmd msg )
        }
    -> ( model, Cmd msg )
apply ( action, { exitFun, modelMapper, msgMapper, transitionFun } ) =
    case action of
        Exit exitAllowed ->
            exitFun exitAllowed

        Transition transitionData ->
            transitionFun transitionData

        Update ( stateModel, stateMsg ) ->
            ( modelMapper stateModel, stateMsg |> Cmd.map msgMapper )
