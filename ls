#!/usr/bin/python3
#+
# Example use of pysmb2. This one is based on the smb2-ls-async.c
# example in the libsmb2 source tree.
#
# Copyright 2020 by Lawrence D'Oliveiro <ldo@geek-central.gen.nz>. This
# script is licensed CC0
# <https://creativecommons.org/publicdomain/zero/1.0/>; do with it
# what you will.
#-

import sys
import time
import asyncio
import getopt
import smb2
from smb2 import \
    SMB2

opts, args = getopt.getopt \
  (
    sys.argv[1:],
    "",
    []
  )
if len(args) != 1 :
    raise getopt.GetoptError("need exactly one arg, the URL to do a listing of")
#end if

loop = asyncio.get_event_loop()

async def mainline() :
    ctx = smb2.Context.create()
    ctx.set_security_mode(SMB2.NEGOTIATE_SIGNING_ENABLED)
    ctx.attach_asyncio(loop)
    url = ctx.parse_url(args[0])
    await ctx.connect_share_async(url.server, url.share, url.user)
    dir = await ctx.opendir_async(("", url.path)[url.path != None])
    while True :
        entry = dir.read()
        if entry == None :
            break
        if entry.name not in (".", "..") :
            sys.stdout.write \
              (
                    "%s %10d %s %s\n"
                %
                    (
                        {
                            SMB2.TYPE_FILE : "-",
                            SMB2.TYPE_DIRECTORY : "d",
                            SMB2.TYPE_LINK : "l",
                        }.get(entry.st.smb2_type, "?"),
                        entry.st.smb2_size,
                        time.strftime("%Y-%b-%d %H:%M:%S", time.localtime(entry.st.smb2_mtime)),
                        entry.name,
                    )
              )
        #end if
    #end while
    dir.close()
    await ctx.disconnect_share_async()
#end mainline

loop.run_until_complete(mainline())
