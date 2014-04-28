# Onenet

Onenet is an experimental implementation of clustered mininet.

The implementation assumes the cluster will be run in EMULab, however, it should be easy to port it to other environments.

[Demo Video](https://vimeo.com/92554805)

## Deployment

You will need to deploy the `onenet` directory in the `emulab`
to the your EMULab home directory. It contains the clustered mininet
implementation that needs to be shared among nodes.

To install all dependencies, you need to do:

```bash
cd control
pip install -r requirements.txt
cd ../frontend
bundle
```

To run it, you need to do:

```bash
cd frontend
bundle exec rackup
```

For executing the experiment, you need to have an active EMULab experiment running (for now). You may use the `emulab/emulab.py` to create the experiment for you by filling in the your credentials and run it by `emulab/emulab.py [number of nodes you want]`.

## Remarks

* EMULab experiments managing is not supported in this release
 
Due to the uncertainty of swapping in/out of experiments in terms of the cost of time and success rate. As forementioned, you can use `emulab/emulab.py` to help you create a compatible experiment automatically though.

## License

MIT License, see LICENSE.

## Authors

Zero Cho <itszero@gatech.edu>
Tao Zhu <tzhu37@gatech.edu>
Baiqian Zhang <brian87@gatech.edu>
Chen Yang <cyang72@gatech.edu>
Yi Ding <yiding@gatech.edu>
