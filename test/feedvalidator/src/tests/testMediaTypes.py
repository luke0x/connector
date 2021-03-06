#!/usr/bin/python
"""$Id: testMediaTypes.py 511 2006-03-07 05:19:10Z rubys $"""

__author__ = "Joseph Walton <http://www.kafsemo.org/>"
__version__ = "$Revision: 511 $"
__date__ = "$Date: 2006-03-07 18:19:10 +1300 (Tue, 07 Mar 2006) $"
__copyright__ = "Copyright (c) 2004 Joseph Walton"
__license__ = "Python"

import os, sys

curdir = os.path.abspath(os.path.dirname(sys.argv[0]))
srcdir = os.path.split(curdir)[0]
if srcdir not in sys.path:
  sys.path.insert(0, srcdir)
basedir = os.path.split(srcdir)[0]

import unittest
from feedvalidator import mediaTypes
from feedvalidator.logging import TYPE_RSS1, TYPE_RSS2, TYPE_ATOM, TYPE_PIE

def l(x):
  if x:
    return x.lower()
  else:
    return x

class MediaTypesTest(unittest.TestCase):
  def testCheckValid(self):
    el = []
    (t, c) = mediaTypes.checkValid(self.contentType, el)

    self.assertEqual(l(t), l(self.mediaType), 'Media type should be ' + self.mediaType)
    self.assertEqual(l(c), l(self.charset), 'Charset should be ' + str(self.charset))
    if (self.error):
      self.assertEqual(len(el), 1, 'Expected errors to be logged')
    else:
      self.assertEqual(len(el), 0, 'Did not expect errors to be logged')


  def testCheckAgainstFeedType(self):
    FT=['Unknown', 'RSS 1.0', 'RSS 2.0', 'Atom', 'Atom 0.3']
    el = []
    r = mediaTypes.checkAgainstFeedType(self.mediaType, self.feedType, el)

    if (self.error):
      self.assertEqual(len(el), 1, 'Expected errors to be logged (' + self.mediaType + ',' + FT[self.feedType] + ')')
    else:
      self.assertEqual(len(el), 0, 'Did not expect errors to be logged (' + self.mediaType + ',' + FT[self.feedType] + ')')

# Content-Type, Media type, Charset, Error?
cvCases = [
  ['text/xml', 'text/xml', 'US-ASCII', False],
  ['text/xml; charset=UTF-8', 'text/xml', 'utf-8', False],
  ['application/xml', 'application/xml', None, False],
  ['text/plain', 'text/plain', 'us-ascii', True],
  ['application/octet-stream', 'application/octet-stream', None, True]
]

# Media type, Feed type, Error?
caftCases = [
  ['text/xml', TYPE_RSS1, False],
  ['application/xml', TYPE_RSS1, False],
  ['application/rss+xml', TYPE_RSS1, False],
  ['application/rdf+xml', TYPE_RSS1, False],
  ['application/x.atom+xml', TYPE_RSS1, True],
  ['application/atom+xml', TYPE_RSS1, True],

  ['text/xml', TYPE_RSS2, False],
  ['application/xml', TYPE_RSS1, False],
  ['application/rss+xml', TYPE_RSS2, False],
  ['application/rdf+xml', TYPE_RSS2, True],
  ['application/x.atom+xml', TYPE_RSS2, True],
  ['application/atom+xml', TYPE_RSS2, True],
  
  ['text/xml', TYPE_ATOM, False],
  ['application/xml', TYPE_ATOM, False],
  ['application/rss+xml', TYPE_ATOM, True],
  ['application/rdf+xml', TYPE_ATOM, True],
  ['application/x.atom+xml', TYPE_ATOM, False],
  ['application/atom+xml', TYPE_ATOM, False],

  ['text/xml', TYPE_PIE, False],
  ['application/xml', TYPE_PIE, False],
  ['application/rss+xml', TYPE_PIE, True],
  ['application/rdf+xml', TYPE_PIE, True],
  ['application/x.atom+xml', TYPE_PIE, True],
  ['application/atom+xml', TYPE_PIE, True],
]

def makeSuite():
  suite = unittest.TestSuite()

  for (ct, mt, cs, e) in cvCases:
     t = MediaTypesTest('testCheckValid')
     t.contentType = ct;
     t.mediaType = mt
     t.charset = cs
     t.error = e
     suite.addTest(t)

  for (mt, ft, e) in caftCases:
    t = MediaTypesTest('testCheckAgainstFeedType')
    t.mediaType = mt
    t.feedType = ft
    t.error = e
    suite.addTest(t)

  return suite

if __name__ == "__main__":
  s = makeSuite()
  unittest.TextTestRunner().run(s)
