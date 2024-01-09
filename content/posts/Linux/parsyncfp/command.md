---
title: "高速同期parsyncfpを試す"
date: 2023-10-14T00:00:00+00:00
# weight: 1
# aliases: ["/first"]
tags: ["rsync", "parsyncfp"]
author: "Me"
showToc: true
TocOpen: false
draft: true
---

# About parsyncfp
* Perl製並列rsyncラッパーで、現在version2。複数のホストへ転送が可能になっているそう
* [License] GPLv3
* [URL] https://github.com/hjmangalam/parsyncfp

* 実行に必要なコマンド
  * ip(Package: iproute2)
  * ethtool
  * fpart
  * scut
  * stats
  * perfquery (Package: infiniband-diags) 
  * iwconfig

# Before Install parsyncfp on Ubuntu 22.04

```
apt-get install fpart ethtool iproute2 infiniband-diags
```

* scut
```
wget http://moo.nac.uci.edu/~hjm/scut
```

* stats
```
wget http://moo.nac.uci.edu/~hjm/parsync/utils/stats -o /usr/local/bin/
```

# Install parsyncfp

```
** FATAL ERROR **: There's no 'fpart' executable on your PATH. Did you install it?
See: https://github.com/martymac/fpart/blob/master/README
```

```
Please select the mail server configuration type that best meets your needs.

 No configuration:
  Should be chosen to leave the current configuration unchanged.
 Internet site:
  Mail is sent and received directly using SMTP.
 Internet with smarthost:
  Mail is received directly using SMTP or by running a utility such
  as fetchmail. Outgoing mail is sent using a smarthost.
 Satellite system:
  All mail is sent to another machine, called a 'smarthost', for
  delivery.
 Local only:
  The only delivered mail is the mail for local users. There is no
  network.

  1. No configuration  2. Internet Site  3. Internet with smarthost  4. Satellite system  5. Local only
General mail configuration type:

General mail configuration type: 1
``````

```
** FATAL ERROR **: [ethtool] not found.  Can't continue without it.
      Check the help page for more info on [ethtool].
```

```
** FATAL ERROR **: [scut] not found.  Can't continue without it.
      Check the help page for more info on [scut].
```

Dockerfile
```
FROM ubuntu:22.04

# Install Ubuntu Packages
RUN apt-get update
RUN echo 1 | apt-get install fpart -y
RUN apt-get install ethtool iproute2 infiniband-diags -y

# Install wcut, stats
RUN apt-get install curl -y
RUN curl http://moo.nac.uci.edu/~hjm/scut -o /usr/local/bin/scut
RUN curl http://moo.nac.uci.edu/~hjm/parsync/utils/stats -o /usr/local/bin/stats
RUN chmod +x /usr/local/bin/{stats,scut}

# Install perfsyncfp
RUN apt-get install git -y
RUN git clone https://github.com/hjmangalam/parsyncfp.git
RUN cp parsyncfp/parsyncfp /usr/local/bin/
RUN chmod +x /usr/local/bin/parsyncfp
```
