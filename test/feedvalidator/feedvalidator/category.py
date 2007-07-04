"""$Id: category.py 610 2006-04-24 19:30:21Z rubys $"""

__author__ = "Sam Ruby <http://intertwingly.net/> and Mark Pilgrim <http://diveintomark.org/>"
__version__ = "$Revision: 610 $"
__date__ = "$Date: 2006-04-25 07:30:21 +1200 (Tue, 25 Apr 2006) $"
__copyright__ = "Copyright (c) 2002 Sam Ruby and Mark Pilgrim"
__license__ = "Python"

from base import validatorBase
from validators import *

#
# author element.
#
class category(validatorBase, rfc3987_full, nonhtml):
  def getExpectedAttrNames(self):
    return [(None,u'term'),(None,u'scheme'),(None,u'label')]

  def prevalidate(self):
    self.children.append(True) # force warnings about "mixed" content

    if not self.attrs.has_key((None,"term")):
      self.log(MissingAttribute({"parent":self.parent.name, "element":self.name, "attr":"term"}))

    if self.attrs.has_key((None,"scheme")):
      self.value=self.attrs.getValue((None,"scheme"))
      rfc3987_full.validate(self, extraParams={"element": "scheme"})

    if self.attrs.has_key((None,"label")):
      self.value=self.attrs.getValue((None,"label"))
      nonhtml.validate(self)
