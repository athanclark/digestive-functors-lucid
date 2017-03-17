--------------------------------------------------------------------------------
{-# LANGUAGE
    OverloadedStrings
  , ExtendedDefaultRules
  #-}

module Text.Digestive.Lucid.Html5
    ( inputText
    , inputTextArea
    , inputPassword
    , inputHidden
    , inputSelect
    , inputSelectGroup
    , inputRadio
    , inputCheckbox
    , inputFile
    , inputSubmit
    , inputWithType
    , label
    , form
    , errorList
    , childErrorList
    , ifSingleton
    ) where


--------------------------------------------------------------------------------
import           Control.Monad               (forM_, when)
import           Data.Text                   (Text, pack)
import           Lucid

--------------------------------------------------------------------------------
import           Text.Digestive.View


--------------------------------------------------------------------------------
ifSingleton :: Bool -> a -> [a]
ifSingleton False _ = []
ifSingleton True  a = [a]

--------------------------------------------------------------------------------
inputText :: Monad m => Text -> View v -> HtmlT m ()
inputText = inputWithType "text" []


--------------------------------------------------------------------------------
inputTextArea :: ( Monad m
                 ) => Maybe Int         -- ^ Rows
                   -> Maybe Int         -- ^ Columns
                   -> Text              -- ^ Form path
                   -> View (HtmlT m ()) -- ^ View
                   -> HtmlT m ()        -- ^ Resulting HTML
inputTextArea r c ref view = textarea_
    ([ id_     ref'
     , name_   ref'
     ] ++ rows' r ++ cols' c) $
        toHtmlRaw $ fieldInputText ref view
  where
    ref'          = absoluteRef ref view
    rows' (Just x) = [rows_ $ pack $ show x]
    rows' _        = []
    cols' (Just x) = [cols_ $ pack $ show x]
    cols' _        = []


--------------------------------------------------------------------------------
inputPassword :: Monad m => Text -> View v -> HtmlT m ()
inputPassword = inputWithType "password" []


--------------------------------------------------------------------------------
inputHidden :: Monad m => Text -> View v -> HtmlT m ()
inputHidden = inputWithType "hidden" []


--------------------------------------------------------------------------------
inputSelect :: Monad m => Text -> View (HtmlT m ()) -> HtmlT m ()
inputSelect ref view = select_
    [ id_   ref'
    , name_ ref'
    ] $ forM_ choices $ \(i, c, sel) -> option_
          (value_ (value i) : ifSingleton sel (selected_ "selected")) c
  where
    ref'    = absoluteRef ref view
    value i = ref' `mappend` "." `mappend` i
    choices = fieldInputChoice ref view


-------------------------------------------------------------------------------
-- | Creates a grouped select field using optgroup
inputSelectGroup :: Monad m => Text -> View (Lucid.HtmlT m ()) -> HtmlT m ()
inputSelectGroup ref view = Lucid.select_
    [ id_   ref'
    , name_ ref'
    ] $ forM_ choices $ \(groupName, subChoices) -> optgroup_ [label_ groupName] $
          forM_ subChoices $ \(i, c, sel) -> option_
          (value_ (value i) : ifSingleton sel (selected_ "selected")) c
  where
    ref'    = absoluteRef ref view
    value i = ref' `mappend` "." `mappend` i
    choices = fieldInputChoiceGroup ref view


-------------------------------------------------------------------------------
-- | More generic textual input field to support newer input types
-- like range, date, email, etc.
inputWithType
    :: Monad m
    => Text
    -- ^ Type
    -> [Attribute]
    -- ^ Additional attributes
    -> Text
    -> View v
    -> HtmlT m ()
inputWithType ty additionalAttrs ref view = input_ attrs
  where
    ref' = absoluteRef ref view
    attrs = defAttrs `mappend` additionalAttrs
    defAttrs =
      [ type_ ty
      , id_ ref'
      , name_ ref'
      , value_ $ fieldInputText ref view
      ]


--------------------------------------------------------------------------------
inputRadio :: ( Monad m
              ) => Bool              -- ^ Add @br@ tags?
                -> Text              -- ^ Form path
                -> View (HtmlT m ()) -- ^ View
                -> HtmlT m ()        -- ^ Resulting HTML
inputRadio brs ref view = forM_ choices $ \(i, c, sel) -> do
    let val = value i
    input_ $ [type_ "radio", value_ val, id_ val, name_ ref']
               ++ ifSingleton sel checked_
    label_ [for_ val] c
    when brs (br_ [])
  where
    ref'    = absoluteRef ref view
    value i = ref' `mappend` "." `mappend` i
    choices = fieldInputChoice ref view


--------------------------------------------------------------------------------
inputCheckbox :: Monad m => Text -> View (HtmlT m ()) -> HtmlT m ()
inputCheckbox ref view = input_ $
    [ type_ "checkbox"
    , id_   ref'
    , name_ ref'
    ] ++ ifSingleton selected checked_
  where
    ref'     = absoluteRef ref view
    selected = fieldInputBool ref view


--------------------------------------------------------------------------------
inputFile :: Monad m => Text -> View (HtmlT m ()) -> HtmlT m ()
inputFile ref view = input_
    [ type_  "file"
    , id_    ref'
    , name_  ref'
    ]
  where
    ref'  = absoluteRef ref view


--------------------------------------------------------------------------------
inputSubmit :: Monad m => Text -> HtmlT m ()
inputSubmit value = input_
    [ type_  "submit"
    , value_ value
    ]


--------------------------------------------------------------------------------
label :: Monad m => Text -> View v -> HtmlT m () -> HtmlT m ()
label ref view = label_
    [ for_ ref'
    ]
  where
    ref' = absoluteRef ref view


--------------------------------------------------------------------------------
form :: Monad m => View (HtmlT m ()) -> Text -> HtmlT m () -> HtmlT m ()
form view action = form_
    [ method_  "POST"
    , enctype_ (pack $ show $ viewEncType view)
    , action_  action
    ]


--------------------------------------------------------------------------------
errorList :: Monad m => Text -> View (HtmlT m ()) -> HtmlT m ()
errorList ref view = case errors ref view of
    []   -> mempty
    errs -> ul_ [class_ "digestive-functors-error-list"] $ forM_ errs $ \e ->
              li_ [class_ "digestive-functors-error"] e


--------------------------------------------------------------------------------
childErrorList :: Monad m => Text -> View (HtmlT m ()) -> HtmlT m ()
childErrorList ref view = case childErrors ref view of
    []   -> mempty
    errs -> ul_ [class_ "digestive-functors-error-list"] $ forM_ errs $ \e ->
              li_ [class_ "digestive-functors-error"] e
