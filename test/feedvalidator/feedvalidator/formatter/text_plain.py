"""$Id: text_plain.py 511 2006-03-07 05:19:10Z rubys $"""

__author__ = "Sam Ruby <http://intertwingly.net/> and Mark Pilgrim <http://diveintomark.org/>"
__version__ = "$Revision: 511 $"
__date__ = "$Date: 2006-03-07 18:19:10 +1300 (Tue, 07 Mar 2006) $"
__copyright__ = "Copyright (c) 2002 Sam Ruby and Mark Pilgrim"
__license__ = "Python"

"""Output class for plain text output"""

from base import BaseFormatter
import feedvalidator

class Formatter(BaseFormatter):
  def format(self, event):
    return '%s %s%s' % (self.getLineAndColumn(event), self.getMessage(event),
      self.getCount(event))
