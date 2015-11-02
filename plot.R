#options(warn=-1)

Targets <- c(55, 65, 75, 85)
Model_Window_Size <- 300

argTime <- function(arg) {
    epoch <- as.numeric(arg)
    as.POSIXct(epoch, origin="1970-01-01")
}

model <- function(time_now, data) {
    t1 <- time_now - Model_Window_Size
    t2 <- time_now
    recent <- data[data$time > t1 && data$time < t2,]
    if (nrow(recent) < 3) {
        return(NULL)
    }
    lm(recent$temperature ~ recent$time)
}

args <- commandArgs(trailingOnly = TRUE)

time_origin <- argTime(args[1])
time_now    <- argTime(args[2])
oven        <- read.table(args[3], header=TRUE)
food        <- read.table(args[4], header=TRUE)
png_path    <- args[5]
width       <- args[6]
height      <- args[7]

png(png_path, width=width, height=height)

par(cex=3.0, family="mono")

plot(
    food$temperature ~ food$time,
    type="l",

print(time_origin)
print(oven[1:5,])
print(food[1:5,])
print(png_path)
