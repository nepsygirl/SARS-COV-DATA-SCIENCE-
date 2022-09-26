import re
from Bio import SeqIO
from Bio.SeqUtils.CheckSum import seguid
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import datetime
import pandas as pd
from sys import argv

def group_fasta(input_file: str) -> None:
    def get_index_key(id_name: str) -> tuple:
        #https://stackoverflow.com/questions/69419403/how-to-sort-a-fasta-file-based-on-date
        try:
            key = (re.search(r'\d{4}-\d{2}-\d{2}', id_name).group(), seguid(id_name))
        except AttributeError:
            key = ('0001-01-01', seguid(id_name))
        return key
    dict_fasta = SeqIO.index(input_file, "fasta", key_function=get_index_key)
    sorted_keys_by_date = sorted(list(dict_fasta), reverse=False, key = lambda d: list(map(int, d[0].split('-'))))
    dates_only = [i[0] for i in sorted_keys_by_date]
    
    my_dict = {i:dates_only.count(i) for i in dates_only}
    return(my_dict)

def plot_seq_per_day(df,location):
    #https://stackoverflow.com/questions/37934242/hierarchical-axis-labeling-in-matplotlib-python
    ax = df.plot.bar(x='Date',y='num_seq',legend=None)
    ax.set_xticklabels([])
    ax.yaxis.grid()
    # ax.set_title('North RhineWestphalia (NRW) 2021', fontsize=15)
    ax.set_title(str(location+' 2021'), fontsize=15)
    # Second X-axis
    ax2 = ax.twiny()

    ax2.spines["bottom"].set_position(("axes", -0.10))
    ax2.tick_params('both', length=0, width=0, which='minor')
    ax2.tick_params('both', direction='in', which='major')
    ax2.xaxis.set_ticks_position("bottom")
    ax2.xaxis.set_label_position("bottom")

    ax2.set_xticks([0,31/365,59/365,90/365,120/365,151/365,181/365,212/365,243/365,273/365,304/365,334/365,1])
    ax2.xaxis.set_major_formatter(ticker.NullFormatter())
    ax2.xaxis.set_minor_locator(ticker.FixedLocator([0.5/12, 1.5/12,2.5/12,3.5/12,4.5/12,5.5/12,6.5/12,7.5/12,8.5/12,9.5/12,10.5/12,11.5/12]))
    ax2.xaxis.set_minor_formatter(ticker.FixedFormatter(['Jan', 'Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']))

    ax.set_xlabel('Month',fontsize=10)
    ax.set_ylabel('Number of sequences',fontsize=10)

    plt.savefig(str(location+'_num_seq_per_day.pdf'))
    return


def main(argv):
    
    if len(argv) != 3:
        print('Please add path and name of the fasta file and location of the data! \n e.g.: python3 plot_num_seq.py /home/ducanor/namuun/sars-cov2-project/berlin-data/sequences_Berlin_2021.fasta Berlin')
        return
    else:  
        try: 
            input_file = argv[1]
            location = argv[2]
            grouped_dict = group_fasta(input_file)

            #https://stackoverflow.com/questions/50708359/python-add-missing-dates-and-update-corresponding-list
            # add missing dates into the dict
            startDate = datetime.datetime.strptime( '2021-01-01', "%Y-%m-%d") # parse first date
            endDate   = datetime.datetime.strptime( '2021-12-31',"%Y-%m-%d") # parse last date 
            days = (endDate - startDate).days  # how many days between?

            # create a dictionary of all dates with 0 occurences
            allDates = {datetime.datetime.strftime(startDate+datetime.timedelta(days=k), "%Y-%m-%d"):0 for k in range(days+1)}

            # update dictionary with existing occurences (zip creates (date,number) tuples)
            allDates.update(  zip(list(grouped_dict.keys()),list(grouped_dict.values())) )

            data_df = pd.DataFrame(allDates.items(), columns=['Date', 'num_seq'])
            plot_seq_per_day(data_df,str(location))

        except Exception as e:  # pragma: nocover
            return "An error has occured: " + str(e)
if __name__ == "__main__":  # pragma: nocover
    main(argv)