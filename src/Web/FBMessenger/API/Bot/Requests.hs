{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DeriveGeneric              #-}
-- {-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE TypeOperators              #-}

-- | This module contains data objects which represents requests to Messenger Platform Bot API
module Web.FBMessenger.API.Bot.Requests 
    ( -- * Types
      Button (..)
    , Element (..)
    , Recipient (..)
    , TextMessage (..)
    , NotificationType (..)
    , SendTextMessageRequest (..)
    , SendStructuredMessageRequest (..)
    -- * Functions
    , makeRecipient
    , makeImageMessageRequest
    , makeGenericTemplateMessageRequest
) where

import           Data.Aeson
import           Data.Aeson.Types
import           Data.Maybe
import           Data.Proxy
import           Data.Text (Text)
import qualified Data.Text as T
import           GHC.Generics
import           GHC.TypeLits
import           Web.FBMessenger.API.Bot.JsonExt


-- | This object represents a text message request
data SendTextMessageRequest = SendTextMessageRequest
  { message_recipient         :: Recipient
  , message_message           :: TextMessage
  , message_notification_type :: Maybe NotificationType
  } deriving (Show, Generic)

instance ToJSON SendTextMessageRequest where
  toJSON = toJsonDrop 8

instance FromJSON SendTextMessageRequest where
  parseJSON = parseJsonDrop 8


-- | This object represents a structured message request
data SendStructuredMessageRequest = SendStructuredMessageRequest
  { structured_message_recipient         :: Recipient
  , structured_message_message           :: StructuredMessage         
  , structured_message_notification_type :: Maybe NotificationType
  } deriving (Show, Generic)

instance ToJSON SendStructuredMessageRequest where
  toJSON = toJsonDrop 19

instance FromJSON SendStructuredMessageRequest where
  parseJSON = parseJsonDrop 19


-- | Informations about the recipient of the message
data Recipient = Recipient 
  { recipient_phone_number :: Maybe Text  -- Phone number of the recipient with the format +1(212)555-2368
  , recipient_id           :: Maybe Text  -- ID of recipient
  } deriving (Show, Generic)

instance ToJSON Recipient where
    toJSON = toJsonDrop 10

instance FromJSON Recipient where
    parseJSON = parseJsonDrop 10


-- | Content of the message for a text-only message
data TextMessage = TextMessage 
  { text_message_text :: Text       -- Message text, must be UTF-8, 320 character limit 
  } deriving (Show, Generic)

instance ToJSON TextMessage where
    toJSON = toJsonDrop 13

instance FromJSON TextMessage where
    parseJSON = parseJsonDrop 13


-- | Push notification type for the message
data NotificationType = Regular        -- will emit a sound/vibration and a phone notification (default)
                      | SilentPush     -- will just emit a phone notification
                      | NoPush         -- will not emit either
                      deriving Show

instance ToJSON NotificationType where
  toJSON Regular    = "REGULAR"
  toJSON SilentPush = "SILENT_PUSH"
  toJSON NoPush     = "NO_PUSH"

instance FromJSON NotificationType where
  parseJSON "REGULAR"     = pure Regular
  parseJSON "SILENT_PUSH" = pure SilentPush
  parseJSON "NO_PUSH"     = pure NoPush
  parseJSON _             = fail "Failed to parse NotificationType"


-- TODO: use message.attachment for StructuredMessages 
--       see https://developers.facebook.com/docs/messenger-platform/send-api-reference#request
-- Consider to reimplement separating by hand all the various possible requests (image, and the three templates)

-- | Type of attachment for a structured message
data AttachmentType = AttachmentImage 
                    | AttachmentTemplate 
                    deriving Show

instance ToJSON AttachmentType where
  toJSON AttachmentImage    = "image"
  toJSON AttachmentTemplate = "template"

instance FromJSON AttachmentType where
  parseJSON "image"    = pure AttachmentImage
  parseJSON "template" = pure AttachmentTemplate
  parseJSON _          = fail "Failed to parse AttachmentType"


-- | Attachment for a structured message
data MessageAttachment = MessageAttachment
  { message_attachment_type    :: AttachmentType
  , message_attachment_payload :: AttachmentPayload
  } deriving (Show, Generic)

instance ToJSON MessageAttachment where
    toJSON = toJsonDrop 19

instance FromJSON MessageAttachment where
    parseJSON = parseJsonDrop 19
    

-- | Payload of attachment for structured messages
data AttachmentPayload = 
    ImagePayload { img_url :: Text } 
  | GenericTemplate 
    { gen_template_type  :: TemplateType          -- Value must be "generic"
    , gen_elements       :: [Element]             -- Data for each bubble in message 
    }
  | ButtonTemplate  
    { btn_template_type  :: TemplateType          -- Value must be "button"
    , btn_text           :: Text                  -- Text that appears in main body
    , btn_buttons        :: [Button]              -- Set of buttons that appear as call-to-actions
    }
  | ReceiptTemplate 
    { rcp_template_type  :: TemplateType          -- Value should be "receipt"
    , rcp_recipient_name :: Text                  -- Recipient's Name
    , rcp_order_number   :: Text                  -- Order number. Must be unique
    , rcp_currency       :: Text                  -- Currency for order
    , rcp_payment_method :: Text                  -- Payment method details. This can be a custom string. Ex: 'Visa 1234'
    , rcp_timestamp      :: Maybe Text            -- Timestamp of order
    , rcp_order_url      :: Maybe Text            -- URL of order
    , rcp_elements       :: [ReceiptElements]     -- Items in order       
    , rcp_address        :: Maybe ShippingAddress -- Shipping address
    , rcp_summary        :: PaymentSummary        -- Payment summary
    , rcp_adjustment     :: PaymentAdjustments    -- Payment adjustments
    }     
  deriving (Show, Generic)

instance ToJSON AttachmentPayload where
    toJSON = toJsonDrop 4

instance FromJSON AttachmentPayload where
    parseJSON = parseJsonDrop 4


-- | Template type for structured messages
data TemplateType = GenericTType | ButtonTType | ReceiptTType deriving (Show)

instance ToJSON TemplateType where
  toJSON GenericTType = "generic"
  toJSON ButtonTType  = "button"
  toJSON ReceiptTType = "receipt"

instance FromJSON TemplateType where
  parseJSON "generic" = pure GenericTType
  parseJSON "button"  = pure ButtonTType
  parseJSON "receipt" = pure ReceiptTType
  parseJSON _         = fail "Failed to parse TemplateType"


-- | Button object for structured messages payloads
data Button = Button 
  { btn_type    :: ButtonType   -- Value is "web_url" or "postback"
  , btn_title   :: Text         -- Button title
  , btn_url     :: Maybe Text   -- For web_url buttons, this URL is opened in a mobile browser when the button is tapped. Required if type is "web_url"
  , btn_payload :: Maybe Text   -- For postback buttons, this data will be sent back to you via webhook. Required if type is "postback"
  } deriving (Show, Generic)

instance ToJSON Button where
    toJSON = toJsonDrop 4
    
instance FromJSON Button where
  parseJSON = parseJsonDrop 4


-- | Type for Button objects
data ButtonType = WebUrl | Postback deriving (Show)

instance ToJSON ButtonType where
  toJSON WebUrl    = "web_url"
  toJSON Postback  = "postback"

instance FromJSON ButtonType where
  parseJSON "web_url"  = pure WebUrl
  parseJSON "postback" = pure Postback
  parseJSON _          = fail "Failed to parse ButtonType"


-- | Elements object for structured messages payloads
data Element = Element
  { elm_title      :: Text           -- Bubble title
  , elm_item_url   :: Maybe Text     -- URL that is opened when bubble is tapped
  , elm_image_url  :: Maybe Text     -- Bubble image
  , elm_subtitle   :: Maybe Text     -- Bubble subtitle
  , elm_buttons    :: Maybe [Button] -- Set of buttons that appear as call-to-actions
  } deriving (Show, Generic)

instance ToJSON Element where
    toJSON = toJsonDrop 4

instance FromJSON Element where
    parseJSON = parseJsonDrop 4

    
-- TODO: replace these stubs with actual types

type ReceiptElements = Text
type ShippingAddress = Text
type PaymentSummary = Text
type PaymentAdjustments = Text


-- | Content of the message for a structured message
data StructuredMessage = StructuredMessage 
  { structured_message_attachment :: MessageAttachment       -- Message text, must be UTF-8, 320 character limit 
  } deriving (Show, Generic)

instance ToJSON StructuredMessage where
    toJSON = toJsonDrop 19

instance FromJSON StructuredMessage where
    parseJSON = parseJsonDrop 19


-- TODO: implement constructors for
-- genericTemplateMessage
-- buttonTemplateMessage
-- receiptTemplateMessage
-- webUrlButton
-- postbackButton
-- element

-- | Takes `id` and `phone_number` and return a Maybe Recipient object.
--   Return Nothing when values are either both (Just _) or both Nothing.  
makeRecipient :: Maybe Text -> Maybe Text -> Maybe Recipient
makeRecipient Nothing Nothing   = Nothing
makeRecipient (Just _) (Just _) = Nothing
makeRecipient rid phone_number   = pure Recipient { recipient_id = rid, recipient_phone_number = phone_number } 

-- | Takes a recipient, a text and a notification type (optional) and return a SendTextMessageRequest
makeTextMessageRequest :: Recipient -> Text -> Maybe NotificationType -> SendTextMessageRequest
makeTextMessageRequest r t nt = SendTextMessageRequest
  { message_recipient         = r
  , message_message           = text_message
  , message_notification_type = nt
  }
  where text_message = TextMessage{ text_message_text = t }

-- | Takes a recipient, an image url and a notification type (optional).
--   Return a SendStructuredMessageRequest for a structured message with image attachment
makeImageMessageRequest :: Recipient -> Text -> Maybe NotificationType -> SendStructuredMessageRequest
makeImageMessageRequest r u nt = SendStructuredMessageRequest
  { structured_message_recipient         = r
  , structured_message_message           = structuredMessage attachment         
  , structured_message_notification_type = nt }
  where attachment = MessageAttachment{ message_attachment_type = AttachmentImage, message_attachment_payload = payload }
        payload    = ImagePayload { img_url = u } 

-- | Takes a recipient, a list of Elements and a notification type (optional).
--   Return a SendStructuredMessageRequest for a structured message with generic template
makeGenericTemplateMessageRequest :: Recipient -> [Element] -> Maybe NotificationType -> SendStructuredMessageRequest
makeGenericTemplateMessageRequest r els nt = SendStructuredMessageRequest
  { structured_message_recipient         = r
  , structured_message_message           = structuredMessage attachment         
  , structured_message_notification_type = nt }
  where attachment = MessageAttachment{ message_attachment_type = AttachmentTemplate, message_attachment_payload = payload }
        payload    = GenericTemplate{ gen_template_type = GenericTType, gen_elements = els } 


-- Helpers, not exported
structuredMessage :: MessageAttachment -> StructuredMessage
structuredMessage attachment = StructuredMessage{ structured_message_attachment = attachment }
