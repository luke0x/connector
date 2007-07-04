"""$Id: generator.py 511 2006-03-07 05:19:10Z rubys $"""

__author__ = "Sam Ruby <http://intertwingly.net/> and Mark Pilgrim <http://diveintomark.org/>"
__version__ = "$Revision: 511 $"
__date__ = "$Date: 2006-03-07 18:19:10 +1300 (Tue, 07 Mar 2006) $"
__copyright__ = "Copyright (c) 2002 Sam Ruby and Mark Pilgrim"
__license__ = "Python"

from base import validatorBase
from validators import *

#
# Atom generator element
#
class generator(nonhtml,rfc2396):
  def getExpectedAttrNames(self):
    return [(None, u'uri'), (None, u'version')]

  def prevalidate(self):
    if self.attrs.has_key((None, "url")):
      self.value = self.attrs.getValue((None, "url"))
      rfc2396.validate(self, extraParams={"attr": "url"})
    if self.attrs.has_key((None, "uri")):
      self.value = self.attrs.getValue((None, "uri"))
      rfc2396.validate(self, errorClass=InvalidURIAttribute, extraParams={"attr": "uri"})
    self.value=''
