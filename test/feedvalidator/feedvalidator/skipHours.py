"""$Id: skipHours.py 511 2006-03-07 05:19:10Z rubys $"""

__author__ = "Sam Ruby <http://intertwingly.net/> and Mark Pilgrim <http://diveintomark.org/>"
__version__ = "$Revision: 511 $"
__date__ = "$Date: 2006-03-07 18:19:10 +1300 (Tue, 07 Mar 2006) $"
__copyright__ = "Copyright (c) 2002 Sam Ruby and Mark Pilgrim"
__license__ = "Python"

from base import validatorBase
from validators import text
from logging import *

#
# skipHours element
#
class skipHours(validatorBase):
    
  def __init__(self):
    self.hours = []
    validatorBase.__init__(self)

  def validate(self):
    if "hour" not in self.children:
      self.log(MissingElement({"parent":self.name, "element":"hour"}))
    if len(self.children) > 24:
      self.log(NotEnoughHoursInTheDay({}))

  def do_hour(self):
    return hour()

class hour(text):
  def validate(self):
    try:
      h = int(self.value)
      if (h < 0) or (h > 24):
        raise ValueError
      elif h in self.parent.hours or (h in [0,24] and 24-h in self.parent.hours):
        self.log(DuplicateValue({"parent":self.parent.name, "element":self.name, "value":self.value}))
      else:
        self.parent.hours.append(h)
        self.log(ValidHour({"parent":self.parent.name, "element":self.name, "value":self.value}))
    except ValueError:
      self.log(InvalidHour({"parent":self.parent.name, "element":self.name, "value":self.value}))
