-----------------------------------------------------------------------------
-- |
-- Module    : BenchSuite.Queries.AllSat
-- Copyright : (c) Jeffrey Young
--                 Levent Erkok
-- License   : BSD3
-- Maintainer: erkokl@gmail.com
-- Stability : experimental
--
-- Bench suite for Documentation.SBV.Examples.Queries.AllSat
-----------------------------------------------------------------------------


module BenchSuite.Queries.AllSat(benchmarks) where

import Documentation.SBV.Examples.Queries.AllSat

import BenchSuite.Bench.Bench

benchmarks :: Runner
benchmarks = runIO "AllSat" demo
