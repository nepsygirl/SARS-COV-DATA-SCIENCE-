import pandas as pd
from sys import argv
import seaborn as sns
import numpy as np
import matplotlib.pyplot as plt

# merging the different csv files using command line tool -> 
# $ csvjoin -c date *.csv > merged_file.csv # join by column "date"
# merged_file.csv is then given as input for this script to plot heatmap of the correlations. 
# This script is for plotting the pearsons correlation between the reported cases and the estimated phi values and incidence estimation from GInPipe using different settings.

def main(argv):
    if len(argv) != 3:
        print('Please add path and name of the merged csv file and its location! \n e.g.: python3 corr_incidence_reported.py /home/ducanor/namuun/sars-cov2-project/berlin-data/merged_file.csv Berlin')
        # python3 corr_incidence_reported.py /home/ducanor/namuun/sars-cov2-project/nrw-data/merged_file_nrw.csv NRW
        return
    else:  
        try: 
            df = pd.read_csv(argv[1], sep = ',')
            # different days per bin #df_corr = df[["new_cases","smoothMedian","phi","smoothMedian_max","phi_max","smoothMedian_min","phi_min"]]
            # different binsize 5, 15 and 25 :
            
            df_corr = df[["new_cases","smoothMedian","phi","smoothMedian_bin_size25","phi_bin_size25","smoothMedian_bin_size5","phi_bin_size5"]]
            #print(df_corr)
            dc = df_corr.corr()

            sns.set(rc = {'figure.figsize':(20,8)})
            matrix = np.triu(dc)
            hm = sns.heatmap(dc, annot = True, mask=matrix)
            hm.set(title = "Correlation between real data and GInPipe estimated values in "+argv[2]+" data \n")

            plt.savefig("Correlation_HeatMap"+argv[2]+"_data.pdf")

        except Exception as e: 
            return "An error has occured: " + str(e)
if __name__ == "__main__": 
    main(argv)