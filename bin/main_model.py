#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Created on Tue May 15, 2018 10:24:00
@author: Constellation Brands
'''

from cbi_ds_common.setup import config

from project_common import ProjectDefaults


class Defaults(ProjectDefaults):
    """
    Defaults
    """
    # OVERRIDE DEFAULT OPTIONS
    # arg1 = 1
    # arg2 = 2

    # LOCAL DEVELOPER OPTIONS
    auditing = False
    debugging = True
    logging = True
    verbose = False
    console = True

    # REQUIRED STATIC VALUES
    process = 'MODEL'


def execute(cfg, **extra):
    """
    Model process of the project to allow seperation of the modeling specifics of the project.

    Arguments: cfg
    """
    cfg.log.push_prefix(Defaults.process)
    # TODO: DEV HERE
    cfg.log.pop_prefix()


def main():
    """
    Main Call for Modeling
    """

    cfg, func_args = config(Defaults)
    execute(**func_args)
    cfg.done()


if __name__ == '__main__':
    main()
    exit(0)
