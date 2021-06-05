
import getopt,argparse

class mixGetOpt:
  def get_opt(self,ref={}):
    if self.skip_get_opt:
      return self

    self.parser = argparse.ArgumentParser(usage=self.usage)

    self.parser.add_argument("-y", "--f_yaml", help="input YAML file",default="")
    self.parser.add_argument("-z", "--f_zlan", help="input ZLAN file",default="")

    self.parser.add_argument("-i", "--f_input_html", help="input HTML file",default="")
    self.parser.add_argument("-f", "--find", help="Find elements via XPATH/CSS",default="")

    self.parser.add_argument("-g", "--grep", help="Grep in input file(s)",default="")
    self.parser.add_argument("--gs", help="Grep scope",default=10)

    self.parser.add_argument("-p", "--print", help="Print field value and exit",default="")

    self.parser.add_argument("-c", "--cmd", help="Run command(s)")
    self.parser.add_argument("-l", "--log", help="Enable logging")

    self.oa = self.parser.parse_args()

    if len(sys.argv) == 1:
      self.parser.print_help()
      sys.exit()

