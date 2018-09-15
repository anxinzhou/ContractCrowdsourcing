import numpy as np
import seaborn as sns
import pandas as pd 
import seaborn as sns
import matplotlib.pyplot as plt


# sns.set(style="whitegrid")
# import ssl
# ssl._create_default_https_context = ssl._create_unverified_context


# titanic = sns.load_dataset("titanic")
# print ((titanic))

# # Draw a nested barplot to show survival for class and sex
# g = sns.catplot(x="class", y="survived", hue="sex", data=titanic,
#                  kind="bar", palette="Set2")

# plt.show()


sns.set(style="darkgrid")
kind = ["Execution cost","Transaction cost"]
name = ['deploy','solicit','reg.','submit','aggr.','appr.','claim']
col = ['kind','name','value']
# tc = [1533368,58283,75749,1401784,473106,29090,83624]
# ec = [1116416,34835,54477,1254944,413562,7818,62352]

#multi task before
# tc = [1176247, 182445, 187706, 1351414,  473106, 29090,47159]
# ec = [846859, 158989, 166306, 1332437, 413562, 7818, 25759]
#multi task after
tc = [1176247 , 61991, 85889, 462673, 170313, 28350, 43000]
ec = [846859, 53735 , 64489, 330705, 110641, 6950, 21600]

tc = np.array(tc)/10000
ec = np.array(ec)/10000



data = []
for n,t,e in zip(name,tc,ec):
	data.append(np.array([kind[0],n,e]))
	data.append(np.array([kind[1],n,t]))


# data = pd.DataFrame(np.array(data),columns=col)
# print(data)

# g = sns.barplot(x="name", y="value", hue="kind", data=data)
# g.despine(left=True)
# g.set_ylabels("survival probability")

size = len(tc)
x = np.arange(size)
total_width,n = 0.6, 2
width = total_width / n 

x = x - (total_width - width) / 2

plt.ylim((0,160))
plt.ylabel('Gas cost (10^4)')
# plt.ylabel('Gas cost (10^4)', family = 'fantasy')
plt.bar(x, tc, width = width, label = 'Transaction cost')
plt.bar(x+width/2,[0]*size,width =width, tick_label = name)
plt.bar(x+width, ec, width =width, label = 'Execution cost')
plt.legend()
plt.show()


