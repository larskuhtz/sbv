-----------------------------------------------------------------------------
-- |
-- Module    : TestSuite.Basics.Tuple
-- Author    : Joel Burget
-- License   : BSD3
-- Maintainer: erkokl@gmail.com
-- Stability : experimental
--
-- Test tuples.
-----------------------------------------------------------------------------

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE TypeApplications    #-}

{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE StandaloneDeriving  #-}
{-# LANGUAGE DeriveDataTypeable  #-}
{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE ScopedTypeVariables #-}

module TestSuite.Basics.Tuple (tests)  where

import Data.SBV.Control
import Data.SBV.List ((.!!), (.:))
import Data.SBV.Tuple

import qualified Data.SBV.List as L

import Utils.SBVTestFramework

data E = A | B | C
mkSymbolicEnumeration ''E

-- Test suite
tests :: TestTree
tests = testGroup "Basics.Tuple" [
          goldenCapturedIO "tuple_swap"   $ t tupleSwapSat
        , goldenCapturedIO "tuple_twoTwo" $ t twoTwoTuples
        , goldenCapturedIO "tuple_nested" $ t nested
        , goldenCapturedIO "tuple_list"   $ t list
        , goldenCapturedIO "tuple_enum"   $ t enum
        ]
    where t tc goldFile = do r <- runSMTWith defaultSMTCfg{verbose=True, redirectVerbose=Just goldFile} tc
                             appendFile goldFile ("\n FINAL: " ++ show r ++ "\nDONE!\n")

tupleSwapSat :: Symbolic ((Integer, Integer, Integer), (Integer, Integer, Integer))
tupleSwapSat = do
  [abx, bay] <- sTuples @(Integer, Integer, Integer) ["abx", "bay"]
  constrain $ abx^._1 .== bay^._2
  constrain $ abx^._2 .== bay^._1
  query $ do _ <- checkSat
             (,) <$> getValue abx <*> getValue bay

twoTwoTuples :: Symbolic ((Integer, String), (Char, Word8))
twoTwoTuples = do
  ab <- sTuple @(Integer, String) "ab"
  cd <- sTuple @(Char,    Word8)  "cd"
  constrain $ ab^._1 .== 1
  constrain $ cd^._1 .== literal 'c'
  query $ do _ <- checkSat
             (,) <$> getValue ab <*> getValue cd

nested :: Symbolic ((Integer, (String, Char)), Word8)
nested = do
  abcd <- sTuple @((Integer, (String, Char)), Word8) "abcd"
  constrain $     abcd^._1^._1 .== 1
  constrain $ abcd^._1^._2^._1 .== literal "foo"
  constrain $ abcd^._1^._2^._2 .== literal 'c'
  constrain $         abcd^._2 .== 0
  query $ do _ <- checkSat
             getValue abcd

list :: Symbolic [(Integer, [(Integer, String)])]
list = do
  lst <- sList @(Integer, [(Integer, String)]) "lst"

  constrain $ (lst .!! 0)^._1 .== 2
  constrain $ (((lst .!! 1)^._2) .!! 0)^._2 .== literal "foo"
  constrain $ L.length lst .== 4
  constrain $ L.length ((lst .!! 1)^._2) .== 5
  constrain $ L.length ((lst .!! 2)^._2) .== 0

  constrain $ lst .== literal [(2,[]), (1,[(3,"foo"), (0,"bar"), (-1,"baz"), (-2,"quux"), (-3,"enough")]), (-4,[]), (-5,[])]

  query $ do _ <- checkSat
             getValue lst

enum :: Symbolic ([(E, [Bool])], (Word8, (E, Float)))
enum = do
   vTup1 :: SList (E, [Bool]) <- sTuple "v1"
   q <- sBool "q"
   constrain $ sNot q
   constrain $ (vTup1 .!! 1)^._2 .== sTrue .: q .: L.nil
   constrain $ L.length vTup1 .== 3

   case untuple (vTup1 .!! 2)  of
     (e, b) -> do constrain $ e .== literal C
                  constrain $ L.length b .== 6
                  constrain $ b .!! 4 .== sTrue

   query $ do
     vTup2 :: STuple2 Word8 (E, Float) <- freshVar "v2"
     constrain $ vTup2 .== literal (5, (C, 8.12))

     constrain $ vTup1 .== literal [(B, []), (A, [True, False]), (C, [False, False, False, False, True, False])]

     _ <- checkSat
     (,) <$> getValue vTup1 <*> getValue vTup2

{-# ANN module ("HLint: ignore Use ." :: String) #-}
