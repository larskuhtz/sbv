-----------------------------------------------------------------------------
-- |
-- Module    : SBVDocTest
-- Copyright : (c) Levent Erkok
-- License   : BSD3
-- Maintainer: erkokl@gmail.com
-- Stability : experimental
--
-- Doctest interface for SBV testsuite
-----------------------------------------------------------------------------

{-# OPTIONS_GHC -Wall -Werror #-}

module Main (main) where

import System.FilePath.Glob (glob)
import Test.DocTest (doctest)

import Data.Char (toLower)
import Data.List (isSuffixOf)

import System.Exit (exitSuccess)

import Utils.SBVTestFramework (getTestEnvironment, TestEnvironment(..), CIOS(..))

import System.Random (randomRIO)

-- For temporarily testing only a few files
testOnly :: FilePath -> Bool
testOnly f = case only of
               Nothing -> True
               Just xs -> any (`isSuffixOf` f) xs
  where only :: Maybe [FilePath]
        only = Nothing

main :: IO ()
main = do (testEnv, testPercentage) <- getTestEnvironment

          putStrLn $ "SBVDocTest: Test platform: " ++ show testEnv

          case testEnv of
            TestEnvLocal   -> runDocTest False False 100
            TestEnvCI env  -> if testPercentage < 50
                              then do putStrLn $ "Test percentage below threshold, skipping doctest: " ++ show testPercentage
                                      exitSuccess
                              else runDocTest (env == CIWindows) True testPercentage
            TestEnvUnknown  -> do putStrLn "Unknown test environment, skipping doctests"
                                  exitSuccess

 where runDocTest onWindows onRemote tp = do srcFiles <- glob "Data/SBV/**/*.hs"
                                             docFiles <- glob "Documentation/SBV/**/*.hs"

                                             let allFiles  = [f | f <- srcFiles ++ docFiles, testOnly f]
                                                 testFiles = filter (\nm -> not (skipWindows nm || skipRemote nm || skipLocal nm)) allFiles

                                                 packages = [ "async"
                                                            , "crackNum"
                                                            , "mtl"
                                                            , "QuickCheck"
                                                            , "random"
                                                            , "syb"
                                                            , "uniplate"
                                                            ]

                                                 pargs = concatMap (\p -> ["-package", p]) packages
                                                 args  = ["--fast", "--no-magic"]

                                             tfs <- pickPercentage tp testFiles

                                             doctest $ pargs ++ args ++ tfs

         where noGood nm = any $ (`isSuffixOf` map toLower nm) . map toLower

               skipWindows nm
                 | not onWindows = False
                 | True          = noGood nm skipList
                 where skipList = [ "NoDiv0.hs"         -- Has a safety check and windows paths are printed differently
                                  , "BrokenSearch.hs"   -- Ditto
                                  ]
               skipRemote nm
                 | not onRemote = False
                 | True         = noGood nm skipList
                 where skipList = [ "Interpolants.hs"  -- This test requires mathSAT, so can't run on remote
                                  , "HexPuzzle.hs"     -- Doctest is way too slow on this with ghci loading, sigh
                                  ]

               -- These are the doctests we currently skip *everywhere* because there's some issue
               -- with an external tool or some other issue that stops us from fixing it. NB. Each
               -- of these should be accompanied by a ticket!
               skipLocal nm = noGood nm skipList
                 where skipList = []

-- Pick (about) the given percentage of files
pickPercentage :: Int -> [String] -> IO [String]
pickPercentage 100 xs = return xs
pickPercentage   0 _  = return []
pickPercentage   p xs = concat <$> mapM pick xs
  where pick f = do c <- randomRIO (0, 100)
                    return [f | c >= p]
