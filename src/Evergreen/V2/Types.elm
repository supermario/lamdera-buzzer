module Evergreen.V2.Types exposing (..)

import Dict
import Evergreen.V2.Page
import Lamdera
import Time
import Url


type alias Buzz = 
    { playerName : String
    , time : Time.Posix
    , received : Time.Posix
    , latency : Int
    }


type alias FrontendModel =
    { key : Lamdera.Key
    , page : Evergreen.V2.Page.Page
    , playerName : String
    , buzzed : Bool
    , buzzes : (Dict.Dict String Buzz)
    }


type alias Session = 
    { sessionId : Lamdera.SessionId
    , playerName : String
    , buzz : (Maybe Buzz)
    , pingStart : Time.Posix
    , latency : Int
    }


type alias BackendModel =
    { sessions : (Dict.Dict Lamdera.SessionId Session)
    , order : Int
    }


type FrontendMsg
    = UrlClicked Lamdera.UrlRequest
    | UrlChanged Url.Url
    | ChangedNameInput String
    | SubmittedName
    | HitBuzzer
    | HitBuzzerTime Time.Posix
    | HitResetBuzzers
    | NoOpFrontendMsg


type ToBackend
    = GotPong
    | SetPlayerName String
    | Buzzed Time.Posix
    | ResetBuzzers
    | NoOpToBackend


type BackendMsg
    = UserJoined Lamdera.SessionId Lamdera.ClientId
    | StartPing Lamdera.SessionId Time.Posix
    | EndPing Lamdera.SessionId Time.Posix
    | BuzzedTime Lamdera.SessionId Time.Posix Time.Posix
    | NoOpBackendMsg


type ToFrontend
    = NeedPlayerName
    | GotPing
    | ReadyToBuzz String
    | BuzzResult Buzz
    | ResetBuzzers_
    | NoOpToFrontend