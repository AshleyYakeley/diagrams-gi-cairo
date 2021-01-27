{-# LANGUAGE CPP #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Diagrams.Backend.Cairo.List
-- Copyright   :  (c) 2012 Diagrams-cairo team (see LICENSE)
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  diagrams-discuss@googlegroups.com
--
-- Render a diagram directly to a list of lists of Colour values
-- (/i.e./ pixels).
--
-----------------------------------------------------------------------------

module Diagrams.Backend.Cairo.List where

#if __GLASGOW_HASKELL__ < 710
import           Control.Applicative        ((<$>))
#endif

import           Control.Exception          (bracket)

import           Data.Colour
import           Data.Colour.SRGB           (sRGB)
import           Data.Word                  (Word8)

import           Diagrams.Backend.Cairo     (Cairo)
import           Diagrams.Backend.Cairo.Ptr (renderPtr)
import           Diagrams.Prelude           (Any, QDiagram, V2)
import           GI.Cairo.Render            (Format (..))

import           Foreign.Marshal.Alloc      (free)
import           Foreign.Marshal.Array      (peekArray)

-- | Render to a regular list of Colour values.

renderToList :: (Ord a, Floating a) =>
                  Int -> Int -> QDiagram Cairo V2 Double Any -> IO [[AlphaColour a]]
renderToList w h d =
  f 0 <$> bracket (renderPtr w h FormatARGB32 d) free (peekArray $ w*h*4)
 where
  f :: (Ord a, Floating a) => Int -> [Word8] -> [[AlphaColour a]]
  f _ [] = []
  f n xs | n >= w = [] : f 0 xs
  f n (g:b:r:a:xs) =
    let l x = fromIntegral x / fromIntegral a
        c   = sRGB (l r) (l g) (l b) `withOpacity` (fromIntegral a / 255)

    in case f (n+1) xs of
      []    -> [[c]]
      cs:ys -> (c:cs) : ys

  f _ _ = error "renderToList: Internal format error"
