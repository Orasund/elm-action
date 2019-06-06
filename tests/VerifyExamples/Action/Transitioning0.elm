module VerifyExamples.Action.Transitioning0 exposing (..)

-- This file got generated by [elm-verify-examples](https://github.com/stoeffel/elm-verify-examples).
-- Please don't modify this file by hand!

import Test
import Expect

import Action exposing (..)
import Task







spec0 : Test.Test
spec0 =
    Test.test "#transitioning: \n\n    transitioning 42\n    |> Action.config\n    |> Action.withTransition (\\int -> ((int,0),Cmd.none))\n    |> Action.apply\n    |> Tuple.first\n    --> (42,0)" <|
        \() ->
            Expect.equal
                (
                transitioning 42
                |> Action.config
                |> Action.withTransition (\int -> ((int,0),Cmd.none))
                |> Action.apply
                |> Tuple.first
                )
                (
                (42,0)
                )