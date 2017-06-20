# ���뿪���������չ��
library(dplyr)
library(Hmisc)
library(ggplot2)
library(caret)

house <- read.csv(file.choose(), stringsAsFactors = FALSE)
dim(house)
str(house)
summary(house)

load('.RData')
# ����̽��

# ���ͷֲ�
type_freq <- data.frame(table(house$����))
type_p <- ggplot(data = type_freq, mapping = aes(x = reorder(Var1, -Freq),y = Freq)) + geom_bar(stat = 'identity', fill = 'steelblue') + theme(axis.text.x  = element_text(angle = 30, vjust = 0.5)) + xlab('����') + ylab('����')
type_p

# �ѵ���һǧ�׵ķ�������Ϊ����
type <- c('2��2��','2��1��','3��2��','1��1��','3��1��','4��2��','1��0��','2��0��')
house$type.new <- ifelse(house$���� %in% type, house$����,'����')
type_freq <- data.frame(table(house$type.new))
type_p <- ggplot(data = type_freq, mapping = aes(x = reorder(Var1, -Freq),y = Freq)) + geom_bar(stat = 'identity', fill = 'steelblue') + theme(axis.text.x  = element_text(angle = 30, vjust = 0.5)) + xlab('����') + ylab('����')
type_p

# �������̬�Լ���
norm.test(house$���)

# ���۵���̬�Լ���
norm.test(house$�۸�.W.)

# ¥��ֲ�
unique(house$¥��)

# ��¥���Ϊ�����������͸�������
house$floow <- ifelse(substring(house$¥��,1,2) %in% c('����','����','����'), substring(house$¥��,1,2),'����')

# ��¥�����Ͱٷֱȷֲ�
percent <- paste(round(prop.table(table(house$floow))*100,2),'%',sep = '')
df <- data.frame(table(house$floow))
df <- cbind(df, percent)
df

# �Ϻ��������۾���
avg_price <- aggregate(house$����.ƽ����., by = list(house$����), mean)

p <- ggplot(data = avg_price, mapping = aes(x = reorder(Group.1, -x), y = x, group = 1)) + geom_area(fill = 'lightgreen') + geom_line(colour = 'steelblue', size = 2) + geom_point() + xlab('') + ylab('����')
p

# ���ݽ���ʱ��ȷʵ���أ����ǰ�������飬ʹ���������
house$����ʱ��[house$����ʱ�� == ''] <- NA
# �Զ�����������
stat.mode <- function(x, rm.na = TRUE){
  if (rm.na == TRUE){
    y = x[!is.na(x)]
  }
  res = names(table(y))[which.max(table(y))]
  return(res)
}

# �Զ��庯����ʵ�ַ����油
my.impute <- function(data, category.col = NULL, 
                      miss.col = NULL, method = stat.mode){
  impute.data = NULL
  for(i in as.character(unique(data[,category.col]))){
    sub.data = subset(data, data[,category.col] == i)
    sub.data[,miss.col] = impute(sub.data[,miss.col], method)
    impute.data = c(impute.data, sub.data[,miss.col])
  }
  data[,miss.col] = impute.data
  return(data)
}

final_house <- subset(my.impute(house, '����', '����ʱ��'),select = c(����,type.new,floow,���,�۸�.W.,����.ƽ����.,����ʱ��))
final_house <- transform(final_house, builtdate2now = 2016-as.integer(substring(as.character(����ʱ��),1,4)))
final_house <- subset(final_house, select = -����ʱ��)

# ʹ��k-means���࣬̽���Ϻ��ĸ���������Ի���Ϊ����

# �Զ��庯��
tot.wssplot <- function(data, nc, seed=1234){
  #�����Ϊһ��ʱ���ܵ����ƽ����              
  tot.wss <- (nrow(data)-1)*sum(apply(data,2,var)) 
  for (i in 2:nc){
    #����ָ�����������
    set.seed(seed) 
    tot.wss[i] <- kmeans(data, centers=i, iter.max = 100)$tot.withinss
  }
  plot(1:nc, tot.wss, type="b", xlab="Number of Clusters",
       ylab="Within groups sum of squares",col = 'blue',
       lwd = 2, main = 'Choose best Clusters')
}


standrad <- data.frame(scale(final_house[,c('���','�۸�.W.','����.ƽ����.')]))
myplot <- tot.wssplot(standrad, nc = 15)

# ����ͼ�Σ����¿��Խ����ݾ�Ϊ5��
set.seed(1234)
clust <- kmeans(x = standrad, centers = 5, iter.max = 100)
table(clust$cluster)

# ������Ľ�����Ƚϸ����з��ӵ�ƽ��������۸�͵���
aggregate(final_house[,3:5], list(clust$cluster), mean)

# ���վ���Ľ�����鿴�����е�����ֲ�
table(house$����,clust$cluster)

# �����͵�ƽ�����
aggregate(final_house$���, list(final_house$type.new), mean)

# ��������뵥�۵�ɢ��ͼ������������л���
p <- ggplot(data = final_house[,3:5], mapping = aes(x = ���,y = ����.ƽ����., color = factor(clust$cluster)))
p <- p + geom_point(pch = 20, size = 3)
p + scale_colour_manual(values = c("red","blue", "green", "black", "orange"))


# ����¥��;��������Ʊ���
# ��������ɢ����ת��Ϊ���ӣ�Ŀ�ı�������һ���Դ����Ʊ���
final_house$cluster <- factor(clust$cluster)
final_house$floow <- factor(final_house$floow)
final_house$type.new <- factor(final_house$type.new)
# ɸѡ�����������ͱ���
factors <- names(final_house)[sapply(final_house, class) == 'factor']
# �������ͱ���ת���ɹ�ʽformula���Ұ����ʽ
formula <- f <- as.formula(paste('~', paste(factors, collapse = '+')))
dummy <- dummyVars(formula = formula, data = final_house)
pred <- predict(dummy, newdata = final_house)
head(pred)
# ���Ʊ���������final_house���ݼ���
final_house2 <- cbind(final_house,pred)
# ɸѡ����Ҫ��ģ������
model.data <- subset(final_house2,select = -c(1,2,3,8,17,18,24))
# ֱ�Ӷ����ݽ������Իع齨ģ
fit1 <- lm(�۸�.W. ~ .,data = model.data)
summary(fit1)

library(car)
# Box-Coxת��
powerTransform(fit1)

fit2 <- lm(log(�۸�.W.) ~ .,data = model.data)

# ʹ��plot�������ģ�Ͷ��Ե����
opar <- par(no.readonly = TRUE)
par(mfrow = c(2,2))
plot(fit2)
par(opar)