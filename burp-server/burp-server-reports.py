#!/usr/bin/python3
# This script will generate list of outdated
# Create folders /usr/local/share/burp-custom and /var/log/burp-custom
# chmod +x the py file
# Locate this file in  /usr/local/share/burp-custom/burp-custom-reports.py
# link to if desired ln -s /usr/local/share/burp-custom/burp-custom-reports.py /usr/local/bin/burp-custom-reports

""" Notes to add later:
http://staticjinja.readthedocs.org/en/latest/user/advanced.html
http://www.decalage.info/python/html
https://plot.ly/python/bar-charts-tutorial/
"""

# send_to={{ burp_server_send_to }}
# send_from={{ burp_server_send_from }}

import os
import re
import csv
# import sys
# import pprint
import json
# import pickle
from datetime import datetime, timedelta


today_date = datetime.now().strftime('%Y-%m-%d')
log_timestamp = datetime.now().strftime('%Y-%m-%d-%H-%M-%S')
clients_list = {}


""" --- Creating empty dictionary:

"""


def get_file_m_date(file):
    file_time = os.path.getmtime(file)
    file_time = datetime.fromtimestamp(file_time)
    file_time = file_time.strftime('%Y-%m-%d')
    return file_time


def date_check_status(backup_date):
    date_regexp = re.compile(r'''(
        \d{4}    #Year
        (-)?  #Separator
        \d{2}     #Month
        (-)?  #Separator
        \d{2}     #Day
    )''', re.VERBOSE)
    client_date = date_regexp.search(backup_date).group()
    if client_date >= n_days_ago:
        return 'ok'
    else:
        return 'outdated'


def get_time_stamp(client_path):
    burp_links = ('finishing', 'working', 'current')
    for i in range(len(burp_links)):
        time_stamp_file = os.path.join(client_path, burp_links[i], 'timestamp')
        if os.path.isfile(time_stamp_file):
            timestamps = open(time_stamp_file)
            timestamp = timestamps.read()
            timestamps.close()
        else:
            continue
        if timestamp:
            return burp_links[i] + ' ' + timestamp


def get_client_working_status(client_path):
    burp_phases = ('phase3', 'phase2', 'phase1')
    burp_phase_dict = {}
    burp_phase = None
    burp_phase_date = None
    burp_phase_status = None
    for i in range(len(burp_phases)):
        phase_file = os.path.join(client_path, 'working', burp_phases[i])
        if os.path.isfile(phase_file):
            burp_phase = burp_phases[i]
            burp_phase_date = get_file_m_date(phase_file)
            burp_phase_status = date_check_status(burp_phase_date)
            burp_phase_dict.setdefault('b_phase', burp_phase)
            burp_phase_dict.setdefault('b_phase_date', burp_phase_date)
            burp_phase_dict.setdefault('b_phase_status', burp_phase_status)
            return burp_phase_dict
        else:
            burp_phase = 'working unknown'
    burp_phase_dict.setdefault('b_phase', burp_phase)
    return burp_phase_dict


def burp_client_status():
    """
    Format that will be used:
    clients_list = {'client_name':
        { 'b_number'  : 'number',
          'b_date'    : 'date',
          'b_status'  : 'outdated/ok',
          'b_type'    : 'finishing/working/current',
          'quota'   : 'ok/soft/hard',
          'warnings': 'warnings',
          'exclude' : 'yes/no',
          'b_phase' : 'phase1/phase2',
          'b_phase_date' : 'date',
          'b_phase_status' : 'outdated/ok',
          'b_log_date' : 'date of log file',
          'b_log_status' : 'outdated/ok',
          'b_curr_taken' : 'seconds'
        }
    }
    :rtype : dict
    """
    burp_clients = []
    l_clients_list = {}
    stats_dict = {}
    try:
        burp_clients = os.listdir(burp_client_confdir)
    except PermissionError:
        print('Permission denied in' + burp_client_confdir)
        exit()
    except:
        print('Could not list folders in' + burp_client_confdir)
        exit()
    for c in burp_clients:
        b_status = 0
        b_date = 0
        b_number = 0
        b_time = 0
        client = c
        b_phase = None
        b_phase_date = None
        b_phase_status = None
        b_log_date = None
        b_log_status = None
        # Ignore incexc folder and profiles
        if (client == 'incexc') or (client == 'profiles'):
            continue
        client_path = os.path.join(burp_directory, client)
        if os.path.isdir(client_path):
            timestamp = get_time_stamp(client_path)  # call function to get data from timestamp
            timestamp = timestamp.split()  # Set list timestamp example:
            # ['working', '0000008', '2015-05-18', '05:49:01' ]
            b_type = timestamp[0]
            if (b_type == 'working') or (b_type == 'current') or (b_type == 'finishing'):
                if b_type == 'working':
                    burp_phase_status = get_client_working_status(client_path)  # get client phase
                    b_phase = burp_phase_status.get('b_phase')
                    b_phase_date = burp_phase_status.get('b_phase_date')
                    b_phase_status = burp_phase_status.get('b_phase_status')
                b_date = timestamp[2]
                b_time = timestamp[3]
                b_status = date_check_status(b_date)
                b_number = timestamp[1]
            if os.path.isfile(os.path.join(client_path, 'current', 'log.gz')):
                b_log_date = get_file_m_date(os.path.join(client_path, 'current', 'log.gz'))
                b_log_status = date_check_status(b_log_date)
            if os.path.isfile(os.path.join(client_path, 'current', 'backup_stats')):
                stats_file = os.path.join(client_path, 'current', 'backup_stats')
                stats_dict = parse_config(filename=stats_file, stats=True)
        else:
            # If there is no client folder in storage backup
            b_number = "None"
            b_date = "None"
            client_conf_dir = os.path.join(burp_client_confdir, client)
            file_time = get_file_m_date(client_conf_dir)
            file_status = date_check_status(file_time)
            if file_status == 'ok':
                b_status = 'new'
                b_type = 'not started'
            else:
                b_status = 'UNKNOWN'
                b_type = "never"
        l_clients_list.setdefault(client, {})['b_status'] = b_status
        l_clients_list.setdefault(client, {})['b_date'] = b_date
        l_clients_list.setdefault(client, {})['b_time'] = b_time
        l_clients_list.setdefault(client, {})['b_number'] = b_number
        l_clients_list.setdefault(client, {})['b_type'] = b_type
        l_clients_list[str(client)].setdefault('exclude', 'no')
        l_clients_list.setdefault(client, {})['b_phase'] = b_phase
        l_clients_list.setdefault(client, {})['b_phase_date'] = b_phase_date
        l_clients_list.setdefault(client, {})['b_phase_status'] = b_phase_status
        l_clients_list.setdefault(client, {})['b_log_date'] = b_log_date
        l_clients_list.setdefault(client, {})['b_log_status'] = b_log_status
        l_clients_list[client].update({'backup_stats': stats_dict})
    return l_clients_list


def report_outdated(file=None, detail=None):
    if file == 'print':
        file = None
    if detail:
        detail = True
    print('reporting outdated for clients_list: \n', file)
    print_text(client=None, file=file, header=True, detail=detail)
    for v in sorted(clients_list.keys()):
        if clients_list[v]['b_status'] != 'ok':
            client = v
            print_text(client, file, detail=detail)
    if file:
        if os.path.isfile(file):
            print('exported to', file)


def report_to_txt(file=None, detail=None):
    if not file or file == 'default':
        file = txt_clients_status
    if detail:
        detail = True
    total_taken = 0
    print_text(client=None, file=file, header=True, detail=detail)
    for k, v in sorted(clients_list.items()):
        client = k
        print_text(client, file, detail=detail)
        if detail:
            total_taken = total_taken + int(clients_list.get(k).get('backup_stats').get('time_taken'))
    if detail:
        s = total_taken
        foot_notes = str('total time backups taken: {:02}:{:02}:{:02}'.format(s//3600, s%3600//60, s%60))
        print_text(client=None, file=file, footer=foot_notes, detail=detail)
    if file:
        if os.path.isfile(file):
            print('exported to', file)


def print_text(client, file=None, header=None, footer=None, detail=None):
    """
    print only header once with client=None, header=True
    header to file:
    print_text(client=None, file=file, header=True)

    :param client: dict with clients (check burp_client_status())
    :param file: output file
    :param header: print header
    :param detail: adds detailed print of clients
    """
    jt = 11
    f = None
    if file:
        if header:
            f = open(file, 'w')
        else:
            f = open(file, 'a')
    if header:
        print('\n burp report'.ljust(jt*9), str(datetime.now().strftime('%Y-%m-%d %H:%M:%S')), '\n', file=f)
        if detail:
            print('clients'.rjust(jt), 'b_number'.center(jt), 'back_date'.center(jt), 'b_time'.center(jt),
                  'b_status'.center(jt), 'b_type'.center(jt), 'exclude'.center(jt), 'phase'.ljust(jt),
                  'phase_date  '.ljust(jt), 'phase_status'.ljust(jt), 'curr_log'.ljust(jt),
                  'log_status'.ljust(jt), 'time_taken', '\n', file=f)
        else:
            print('Clients'.rjust(jt+jt+jt), 'Number'.center(jt), 'Date'.center(jt), 'Time'.center(jt),
                  'Type'.center(jt), 'Status'.center(jt), '\n', file=f)
    if client:
        v = client
        if detail:
            s = int(clients_list[v].get('backup_stats').get('time_taken'))
            time_taken = str('{:02}:{:02}:{:02}'.format(s//3600, s%3600//60, s%60))
            print(v.rjust(jt), str(clients_list[v].get('b_number')).center(jt),
                  str(clients_list[v].get('b_date')).center(jt),
                  str(clients_list[v].get('b_time')).center(jt),
                  clients_list[v].get('b_status').center(jt),
                  clients_list[v].get('b_type').center(jt),
                  clients_list[v].get('exclude').center(jt),
                  str(clients_list[v].get('b_phase', '')).ljust(jt),
                  str(clients_list[v].get('b_phase_date', '')).ljust(jt),
                  '', str(clients_list[v].get('b_phase_status', '')).ljust(jt),
                  str(clients_list[v].get('b_log_date', '')).ljust(jt),
                  str(clients_list[v].get('b_log_status', '')).ljust(jt),
                  str(time_taken).ljust(jt),
                  file=f
                  )
        else:
            print(v.rjust(jt+jt+jt), str(clients_list[v].get('b_number')).center(jt),
                  str(clients_list[v].get('b_date')).center(jt),
                  str(clients_list[v].get('b_time')).center(jt),
                  clients_list[v].get('b_type').center(jt),
                  clients_list[v].get('b_status').center(jt),
                  file=f
                  )
    if footer:
         if detail:
            print('\n\n'.rjust(jt), ''.center(jt), ''.center(jt), ''.center(jt),
                  ''.center(jt), ''.center(jt), ''.center(jt), ''.ljust(jt),
                  '  '.ljust(jt), ''.ljust(jt), ''.ljust(jt),
                  footer.ljust(jt), '\n', file=f)


def load_csv_data(csv_filename=None):
    if not csv_filename:
        csv_filename = csv_file_data
    if os.path.isfile(csv_filename):
        print('Loading', csv_filename, 'and ignoring first row')
    else:
        return str('we could not read the source csv:', csv_filename)
    csv_rows = []
    csv_file_obj = open(csv_filename)
    reader_obj = csv.reader(csv_file_obj, delimiter=';')
    for row in reader_obj:
        if reader_obj.line_num == 1:
            continue  # skip first row
        csv_rows.append(row)
    return csv_rows


def save_csv_data(csv_rows=None, csv_filename=None):
    if not csv_filename:
        csv_filename = csv_file_data_export
    if not csv_rows:
        return 'There are no csv rows to write'
    print('saving to csv file:', csv_filename)
    csv_file_obj = open(csv_filename, 'w', newline='')
    csv_writer = csv.writer(csv_file_obj, delimiter=';')
    for row in csv_rows:
        csv_writer.writerow(row)
    csv_file_obj.close()
    if csv_filename:
        if os.path.isfile(csv_filename):
            print('exported to:', csv_filename)


def inventory_compare(csv_filename=None):
    if not csv_filename:
        inventory = load_csv_data()
    else:
        inventory = load_csv_data(csv_filename)
    csv_rows_inventory_status = [['client', 'status', 'inv_status', 'sub_status']]
    for i in range(len(inventory)):
        client, status, det_status = inventory[i][0:3]
        if client in clients_list:
            if det_status.lower() == 'spare':
                inv_status = 'wrong spare in burp'
            elif status.lower() != 'active':
                inv_status = 'wrong not active'
            else:
                inv_status = clients_list[client]['b_status']
        elif det_status.lower() == 'spare':
            inv_status = 'ignored spare'
        else:
            inv_status = 'absent'
        row = inventory[i]
        row.insert(1, inv_status)
        csv_rows_inventory_status.append(row)
    return csv_rows_inventory_status


# TODO: def report_web_status():
    # staticjinja could be used.


# TODO: def send_emails():


def parse_config(filename, stats=None):
    """

    :param filename: file name to parse config
    :param stats: only use it to stats file with separator :
    :return: dict with options
    """
    options = {}
    comment_char = '#'
    option_char = '='
    stats_char = ':'
    f = open(filename)
    for line in f:
        # First, remove comments:
        if comment_char in line:
            # split on comment char, keep only the part before
            line, comment = line.split(comment_char, 1)
        # Second, find lines with an option=value:
        if option_char in line and not stats:
            # split on option char:
            option, value = line.split(option_char, 1)
        elif stats_char in line and stats:
            option, value = line.split(stats_char, 1)
        else:
            continue
        if option and value:
            # strip spaces:
            option = option.strip()
            value = value.strip()
            # store in dictionary:
            options[option] = value
    f.close()
    return options


def reports_config_global(burp_custom=None, example=None):
    global burp_automation_folder
    global n_days_ago
    global csv_file_data_export
    global txt_clients_status
    global csv_file_data
    global json_clients_status
    global burp_www_reports
    # Global to parse to help TODO:change it to return and modify all to use classes when learned :)
    global burp_custom_file
    if not burp_custom:
        burp_custom_file = os.path.join(os.sep, 'etc', 'burp', 'burp-custom-reports.conf')
    else:
        burp_custom_file = burp_custom
    # ###### ------------ BURP custom reports variables -------------------- #########
    if os.path.isfile(burp_custom_file):
        if not example:
            print('Loading configuration: ', burp_custom_file)
        # GET FROM burp_custom_file:
        reports_config = parse_config(burp_custom_file)
        # burp automation folder for files in use with list of clients and other with automation tasks.
        # - option: burp_automation_folder = default = /storage/samba/automation
        burp_automation_folder = reports_config.get('burp_automation_folder')
        days_outdated = reports_config.get('days_outdated')
        days_outdated = int(str(days_outdated))
        burp_www_reports = reports_config.get('burp_www_reports')
        json_clients_status = reports_config.get('json_clients_file')
        csv_file_data = reports_config.get('csv_file_data')
    else:
        # if not burp custom file SET DEFAULT VALUES:
        burp_automation_folder = os.path.join(os.sep, 'storage', 'samba', 'automation')
        days_outdated = 10
        burp_www_reports = os.path.join(os.sep, 'var', 'www', 'html')
        json_clients_status = os.path.join(os.sep, 'var', 'spool', 'burp', 'clients_status.json')
        csv_file_data = os.path.join(burp_automation_folder, 'inventory.csv')
    # SET OTHER GLOBAL Variables to use around the script:
    n_days_ago = datetime.now() - timedelta(days=days_outdated)
    n_days_ago = n_days_ago.strftime('%Y-%m-%d')
    csv_file_data_export = os.path.join(burp_www_reports, 'inventory_status.csv')
    txt_clients_status = os.path.join(burp_www_reports, 'clients_status.txt')
    if example:
        print('    Example config for burp custom config file', burp_custom_file,
              '\n        burp_automation_folder =', burp_automation_folder,
              '\n        # csv_file_to compare with external inventory:'
              '\n        csv_file_data =', csv_file_data,
              '\n        days_outdated =', days_outdated,
              '\n        burp_www_reports =', burp_www_reports,
              '\n        # burp_www_reports, is output place for example files:',
              '\n            #', csv_file_data_export, txt_clients_status,
              '\n        json_clients_file =', json_clients_status)


def burp_config_global(burp_conf=None):
    global burp_conf_file
    global burp_directory
    global burp_client_confdir
    # ###### ------------ BURP Main config variables ----------------------- #########
    if not burp_conf:
        burp_conf_file = os.path.join(os.sep, 'etc', 'burp', 'burp-server.conf')
    else:
        burp_conf_file = burp_conf
    if os.path.isfile(burp_conf_file):
        print('Loading variables from: ', burp_conf_file)
        burp_config = parse_config(burp_conf_file)
        burp_directory = burp_config.get('directory')
        burp_client_confdir = burp_config.get('clientconfdir')
    else:
        burp_directory = 'UNKNOWN'
        burp_client_confdir = 'UNKNOWN'


def export_json(file=None):
    if not file:
        file = json_clients_status
    with open(file, 'w') as fp:
        json.dump(clients_list, fp)


def import_json(file=None):
    l_clients_list = {}
    if not file:
        file = json_clients_status
    with open(file, 'r') as fp:
        l_clients_list = json.load(fp)
    return l_clients_list


# TODO: enhance help
def print_usage():
    print('\n'
          '    Import clients_list from json: --i --import_json=file/path\n'
          '        -i runs with default file\n'
          '        --import=/path/to/file does the same as -i but allows you to specify the .json file to import\n'
          '        It is useful to work without scanning the status (like debugging the script)\n'
          '        Default file: ', json_clients_status)
    print('\n'
          '    Export clients_list from json: --export_json=file/path\n'
          '        It is useful to work without scanning the status in other environment\n'
          '        (like debugging the script or working with inventory)\n'
          '        Default file: ', json_clients_status)
    print('\n'
          '    Report outdated --o --outdated\n'
          '        Will print a list of outdated clients')
    print('\n'
          '    Report clients to text file json: --t --text=file/path\n'
          '        -t runs with default file\n'
          '        --text=/path/to/file does the same as -i but allows you to specify the file to export\n'
          '        Default file: ', txt_clients_status)
    print('\n'
          '    Compare with inventory from file csv: --compare=file\n'
          '    csv file must have at least 3 columns with this order and separator ;:\n'
          '        The purpose is to compare and check from external inventory:\n'
          '        client; status; det_status\n'
          '        Status must be: active if not: will ignore the client (is case insensitive).\n'
          '        det_status (sub status), could be empty but should be there at least empty.\n'
          '        If spare the reported status will be: ignored spare\n'
          '        if client is not in burp and does not meet previous conditions, it will be: absent.\n'
          '        Default file: ', csv_file_data)
    print('\n'
          '    you must also specify output csv: --csv_output=file\n'
          '    Default output:', csv_file_data_export)
    print('\n'
          '    Specify burp-config=file\n'
          '    Default:', burp_conf_file)
    print('\n'
          '    Specify burp-reports-config=file\n'
          '    Default:', burp_custom_file)
    print(reports_config_global(burp_custom=None, example=True))
    print('\n'
          '    For all --option you can use --option or --option=arg\n'
          '        If you use --option it will use default value')


def parser_commandline():
    """
    Information extracted from: https://mkaz.com/2014/07/26/python-argparse-cookbook/
    :return:
    """
    import argparse
    global clients_list
    compare_result = []
    parser = argparse.ArgumentParser()
    parser.add_argument('--burp_conf', nargs='?', const=os.path.join(os.sep, 'etc', 'burp', 'burp-server.conf'),
                        help='burp-server.conf file')
    parser.add_argument('--reports_conf', const=os.path.join(os.sep, 'etc', 'burp', 'burp-custom-reports.conf'),
                        nargs='?', help='burp-custom-server.conf file')
    parser.add_argument('--import_json', nargs='?',
                        help='clients_status.json file')
    parser.add_argument('--outdated', '-o', nargs='?', const='print',
                        help='Report outdated or --outdated=file')
    parser.add_argument('--text', '-t', nargs='?', const='default',
                        help='Report to default text file or --text=file')
    parser.add_argument('--detail', default=False, action='store_true',
                        help='Report details on text reports')
    parser.add_argument('--compare', '-co', nargs='?', const='df', help='Compare inventory --compare=file')
    parser.add_argument('--csv_output', nargs='?', const='df', help='export compare to --csv_output=file')
    parser.add_argument('--export_json', nargs='?', const='df', help='export clients_list to file')
    parser.add_argument('--print_usage', nargs='?', default=None, const='Print', help='print usage')
    args = parser.parse_args()
    # Always load some config with or without --burp_conf
    burp_config_global(burp_conf=args.burp_conf)
    # Always set reports config with or without --reports_conf
    reports_config_global(burp_custom=args.reports_conf)
    # Configure options:
    if args.import_json:
        clients_list = import_json(args.import_json)
    else:
        clients_list = burp_client_status()
    if args.outdated:
        report_outdated(file=args.outdated, detail=args.detail)
    if args.text:
        report_to_txt(file=args.text, detail=args.detail)
    if args.compare:
        if args.compare == 'df':
            compare_result = inventory_compare()
        else:
            compare_result = inventory_compare(args.compare)
    if args.csv_output:
        if args.csv_output == 'df':
            save_csv_data(compare_result)
        else:
            save_csv_data(compare_result, args.csv_output)
    if args.export_json:
        if args.export_json == 'df':
            export_json()
        else:
            export_json(args.export_json)
    if args.print_usage == 'Print':
        print_usage()


if __name__ == "__main__":
    parser_commandline()


# #### ---- tests ---- #####
# set global clients_list
# clients_list = {}
# clients_list = burp_client_status() or # clients_list = import_json(file) - file or json_clients_status
# pprint.pprint(clients_list)
# report_to_txt(txt_clients_status)
# report_outdated()
# export_json(file) - file or json_clients_status
# inventory_compare()
