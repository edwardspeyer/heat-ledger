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

recent_t2 <- now - epoch
recent_t1 <- recent_t2 - Model_Window_Size

recent <- food
recent <- recent[recent$time > recent_t1,]
recent <- recent[recent$time < recent_t2,]

done <- data.frame()
if (nrow(recent) >= 3) {
    model <- lm(recent$temperature ~ recent$time)
    a <- model$coefficients[[2]]
    b <- model$coefficients[[1]]
    done <- data.frame(
      temperature=Targets,
      time=(Targets - b) / a  # (T = at + b) so (t = (T - b)/a)
    )
}

temperature_range <- range(c(
    0,
    150,
    food$temperature,
    oven$temperature,
    done$temperature
))

time_range <- range(c(
    0,
    300,
    food$time,
    oven$time,
    done$time  # TODO quantize to avoid xlim jitter as model improves
))

plot(
    food$temperature ~ food$time,
    type="l",
    xlab='',
    ylab='',
    xlim=time_range,
    ylim=temperature_range,
    lwd=4,
)

points(
    oven$temperature ~ oven$time,
    type="l",
    lwd=4,
)

for (target in Targets) {
    abline(target, 0, lt=3, col=8)
    label <- paste(target, "\u00B0C", sep="")
    text(0, target, label, pos=4, col='gray')
}

if (exists("model")) {
    abline(model, lt=2, col='yellow')
    null <- apply(done, 1, function(row) {
        target <- row[[1]]
        time   <- row[[2]]
        abline(v=time, lt=3, col=8)
        label <- strftime(
            as.POSIXct(
                epoch + time,
                origin="1970-01-01"
            ),
            '%H:%M'
        )
        text(time, target, label, pos=2)
        points(time, target, type="p", lwd=4, col="red")
    })
}

graphics.off()
