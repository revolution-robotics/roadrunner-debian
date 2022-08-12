# REVO Roadrunner Blade GPIO configuration

In DTS file *imx7ds.dtsi*, included from *imx7d.dtsi*, included
from *imx7d-roadrunner-blade.dts*, a GPIO controller is defined by

```dts
/ {
    soc {
        aips1: aips-bus@30000000 {
            compatible = "fsl,aips-bus", "simple-bus";
            #address-cells = <1>;
            #size-cells = <1>;
            reg = <0x30000000 0x400000>;
            ranges;

            ...

            gpio2: gpio@30210000 {
                compatible = "fsl,imx7d-gpio", "fsl,imx35-gpio";
                reg = <0x30210000 0x10000>;
                interrupts = <GIC_SPI 66 IRQ_TYPE_LEVEL_HIGH>,
                         <GIC_SPI 67 IRQ_TYPE_LEVEL_HIGH>;
                gpio-controller;
                #gpio-cells = <2>;
                interrupt-controller;
                #interrupt-cells = <2>;
                gpio-ranges = <&iomuxc 0 13 32>;
            };

            ...
        };

        ...
    };
}
```

The property

```dts
compatible = "fsl,imx7d-gpio", "fsl,imx35-gpio";
```

directs us to the document
*kernel/Documentation/devicetree/bindings/gpio/fsl-imx-gpio.txt*,
which indicates that the property:


```dts
#gpio-cells = <2>
```

means that a GPIO specifier is defined by two cells - the first being an offset,
the second a polarity. In other words, the iMX GPIO driver does not
explicitly support setting other GPIO parameters, like pull-up,
as is typical for GPIO drivers.  Indeed, the document
*kernel/Documentation/devicetree/bindings/gpio/gpio.txt*
observes:

> Most controllers are specifying a generic flag bitfield in the
> last cell, so for these, use the macros defined in
> include/dt-bindings/gpio/gpio.h whenever possible.

Consequently,  GPIO pull-ups must be initialized in the pinctrl node.

```dts
&iomuxc {
    pinctrl-names = "default", "sleep";
    pinctrl-0 = <&pinctrl_hog_1>;
    pinctrl-1 = <&pinctrl_hog_1_sleep>;

    imx7d-sdb {
        pinctrl_hog_1: hoggrp-1 {
            fsl,pins = <
                ...
                MX7D_PAD_EPDC_DATA10__GPIO2_IO10	0x76
                MX7D_PAD_EPDC_DATA01__GPIO2_IO1		0x76
                MX7D_PAD_EPDC_DATA04__GPIO2_IO4		0x76
                MX7D_PAD_EPDC_DATA09__GPIO2_IO9		0x76
                MX7D_PAD_EPDC_DATA15__GPIO2_IO15	0x76
                MX7D_PAD_EPDC_DATA03__GPIO2_IO3		0x36
            >;
        };
```
