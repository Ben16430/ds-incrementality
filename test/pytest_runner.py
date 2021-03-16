#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri May 11 10:24:00 2018
@author: Dan Stearns
"""

import os, sys
import unittest


cwd = os.getcwd()
if os.name=='nt':
    wd = os.path.dirname(cwd)
else:
    wd = cwd

bin_dir = os.path.join(wd, 'cbi_ds_common')

if bin_dir not in sys.path:
    sys.path.append(bin_dir)

from cbi_ds_common.config import CBIConfig
cfg = CBIConfig(__file__, env='TEST')

def suite():  # Function stores all the modules to be tested
    alltests = unittest.TestSuite()
    modules_to_test = []
    testcase_dir = os.path.join(cfg.testdir, 'unit_tests')
    sys.path.append(testcase_dir)
    if os.path.isdir(testcase_dir):
        test_files = os.listdir(testcase_dir)

        for test in test_files:
            if test.startswith('test') and test.endswith('.py'):
                modules_to_test.append(test.rstrip('.py'))

        for module in map(__import__, modules_to_test):
            alltests.addTest(unittest.findTestCases(module))

    return alltests


if __name__ == '__main__':
    unittest.main(defaultTest='suite')