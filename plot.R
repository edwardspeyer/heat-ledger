#options(warn=-1)

Targets <- c(55, 65, 75, 85)
Model_Window_Size <- 300

model <- function(time_now, data) {
    t1 <- time_now - Model_Window_Size
    t2 <- time_now
    recent <- data[data$time > t1 && data$time < t2,]
    if (nrow(recent) < 3) {
        return(NULL)
    } else {
        return(lm(recent$temperature ~ recent$time))
    }
}

args <- commandArgs(trailingOnly = TRUE)

epoch       <- as.numeric(args[1])
food        <- read.table(args[2], header=TRUE)
oven        <- read.table(args[3], header=TRUE)
png_path    <-            args[4]
width       <- as.numeric(args[5])
height      <- as.numeric(args[6])

png(png_path, width=width, height=height, units="px")

par(
    cex=3.0,
    family="mono",
    mar=c(
        2.0,    # bottom
        2.0,    # left
        0.5,    # top
        0.5     # right
    )
)

temperature_range <- range(c(
    0,
    150,
    food$temperature,
    oven$temperature
))

time_range <- range(c(
    0,
    300,
    food$time,
    oven$time
))

plot(
    food$temperature ~ food$time,
    type="l",
    xlab='',
    ylab='',
    xlim=time_range,
    ylim=temperature_range
)

points(
    oven$temperature ~ oven$time,
    type="l"
)

graphics.off()
