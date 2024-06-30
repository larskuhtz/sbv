-----------------------------------------------------------------------------
-- |
-- Module    : BenchSuite.Misc.Newtypes
-- Copyright : (c) Jeffrey Young
--                 Levent Erkok
-- License   : BSD3
-- Maintainer: erkokl@gmail.com
-- Stability : experimental
--
-- Bench suite for Documentation.SBV.Examples.Misc.Newtypes
-----------------------------------------------------------------------------


module BenchSuite.Misc.Newtypes(benchmarks) where

import Documentation.SBV.Examples.Misc.Newtypes

import BenchSuite.Bench.Bench


-- benchmark suite
benchmarks :: Runner
benchmarks =  run "Problem" problem
