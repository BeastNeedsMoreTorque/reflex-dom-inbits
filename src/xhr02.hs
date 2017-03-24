{-# LANGUAGE OverloadedStrings #-}
import           Reflex.Dom
import qualified Data.Text as T
import qualified Data.Map as Map
import           Data.Monoid ((<>))
import           Data.Meteo.Swiss
import           Data.Word
import           Control.Monad (when)


main :: IO ()
main = mainWidget body

body :: MonadWidget t m => m ()
body  = el "div" $ do
  el "h2" $ text "Swiss Weather Data (display status fields)"
  text "Choose station: "
  dd <- dropdown "BER" (constDyn stations) def
  evSend <- button "Send"
  -- Build and send the request
  let evCode = tagPromptlyDyn (value dd) evSend
  evRsp <- performRequestAsync $ fmap buildReq evCode

  -- Display the status
  displayStatus evRsp

  -- Display the whole response
  displayRsp evRsp
  return ()

displayRsp :: MonadWidget t m => Event t XhrResponse -> m ()
displayRsp evRsp = do
  el "p" blank
  text "Response Text"
  el "p" blank
  let evResult = (result . _xhrResponse_responseText) <$> evRsp
  dynText =<< holdDyn "" evResult
  return ()

displayStatus :: MonadWidget t m => Event t XhrResponse -> m ()
displayStatus evRsp = do
  -- Display the Staus Word
  el "p"  blank
  text "Status: "
  let evWord = _xhrResponse_status <$> evRsp
  let evWordTxt = fmap word2Txt evWord
  dynText =<< holdDyn "" evWordTxt
  -- Display the status Text
  text " "
  let evStatusText = _xhrResponse_statusText <$> evRsp
  dynText =<< holdDyn "" evStatusText
  return ()

buildReq :: T.Text -> XhrRequest ()
buildReq code = XhrRequest "GET" (urlDataStat code) def

stations :: Map.Map T.Text T.Text
stations = Map.fromList [("BIN", "Binn"), ("BER", "Bern"), ("KLO", "Zurich airport"), ("ZER", "Zermatt"), ("JUN", "Jungfraujoch")]

result :: Maybe T.Text -> T.Text
result (Just t) = t
result Nothing = "Response is Nothing"

word2Txt :: Word -> T.Text 
word2Txt = T.pack . show . word2Int
  where 
    word2Int :: Word -> Int
    word2Int = fromIntegral
