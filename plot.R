Targets <- c(
    55,     # beef muscle, rare
    65,     # poultry, rare
    75,     # poultry, done
    85      # beef tissue, done
)

Model_Window_Size <- 300

args <- commandArgs(trailingOnly = TRUE)

epoch       <- as.numeric(args[1])
now         <- as.numeric(args[2])
food        <- read.table(args[3], header=TRUE)
oven        <- read.table(args[4], header=TRUE)
png_path    <-            args[5]
width       <- as.numeric(args[6])
height      <- as.numeric(args[7])

png(
    png_path,
    width=width,
    height=height,
    units="px"
)

par(
    cex=(width / 640),  # 1920 px wide => cex=3.0
    family="mono",
    col.lab='white',
    col.axis='white',
    fg='white',
    bg='black',
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
    
for (target in Targets) {
    abline(target, 0, lt=3, col=8)
    label <- paste(target, "\u00B0C", sep="")
    text(0, target, label, pos=4, col='gray')
}

t2 <- now - epoch
t1 <- t2 - Model_Window_Size

recent <- food
recent <- recent[recent$time > t1,]
recent <- recent[recent$time < t2,]

if (nrow(recent) >= 3) {
    model <- lm(recent$temperature ~ recent$time)
    # T = at + b  =>  t = (T - b)/a
    a <- model$coefficients[[2]]
    b <- model$coefficients[[1]]
    for (target in Targets) {
        done_time <- (target - b) / a
        abline(v=done_time, lt=3, col=8)
        label <- strftime(
            as.POSIXct(
                epoch + done_time,
                origin="1970-01-01"
            ),
            '%H:%M'
        )
        text(done_time, target, label, pos=2)
        points(done_time, target, type="p", lwd=4, col="red")
    }
}

graphics.off()
